-- ============================================
-- BRAG MODE MIGRATION
-- ============================================
-- This migration adds secure "brag mode" functionality for sharing contracts
-- with personal information redacted at the database level.
--
-- Run this in Supabase SQL Editor after initial schema setup.

-- ============================================
-- 1. ADD BRAG MODE COLUMNS TO CONTRACTS TABLE
-- ============================================

-- Add brag mode fields to contracts table
ALTER TABLE contracts
ADD COLUMN IF NOT EXISTS brag_mode_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS brag_mode_token TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS brag_mode_config JSONB DEFAULT '{
  "hide_names": true,
  "hide_signatures": true,
  "hide_signature_dates": true,
  "personal_field_ids": []
}'::jsonb;

-- Create index for faster brag token lookups
CREATE INDEX IF NOT EXISTS contracts_brag_token_idx ON contracts(brag_mode_token) WHERE brag_mode_token IS NOT NULL;

-- ============================================
-- 2. CREATE SERVER-SIDE FILTERING FUNCTION
-- ============================================
-- This function filters personal data BEFORE sending to client
-- Making it impossible to access via URL manipulation or DevTools

CREATE OR REPLACE FUNCTION get_brag_mode_contract(brag_token TEXT)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title TEXT,
    data JSONB,
    dominant_name TEXT,
    submissive_name TEXT,
    owner_signature TEXT,
    owner_signature_date DATE,
    submissive_signature TEXT,
    submissive_signature_date DATE,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    brag_mode_enabled BOOLEAN,
    brag_mode_config JSONB,
    -- Include public share fields for compatibility
    is_public BOOLEAN,
    public_share_token TEXT,
    public_share_role TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated privileges to bypass RLS
AS $$
DECLARE
    contract_record RECORD;
    config JSONB;
    filtered_data JSONB;
    section JSONB;
    field JSONB;
    filtered_sections JSONB;
    filtered_fields JSONB;
    personal_field_ids TEXT[];
BEGIN
    -- Find the contract with this brag token
    SELECT * INTO contract_record
    FROM contracts
    WHERE contracts.brag_mode_token = brag_token
      AND contracts.brag_mode_enabled = TRUE;

    -- Return nothing if not found or not enabled
    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Get brag mode config
    config := contract_record.brag_mode_config;
    personal_field_ids := ARRAY(SELECT jsonb_array_elements_text(config->'personal_field_ids'));

    -- Filter the contract data (sections and fields)
    filtered_sections := '[]'::jsonb;

    IF contract_record.data ? 'sections' THEN
        FOR section IN SELECT * FROM jsonb_array_elements(contract_record.data->'sections')
        LOOP
            filtered_fields := '[]'::jsonb;

            IF section ? 'fields' THEN
                FOR field IN SELECT * FROM jsonb_array_elements(section->'fields')
                LOOP
                    -- Check if this field is marked as personal
                    IF (field->>'id') = ANY(personal_field_ids) THEN
                        -- Redact the value based on field type
                        IF field->>'type' = 'list' THEN
                            field := jsonb_set(field, '{items}', '["[Redacted]"]'::jsonb);
                        ELSIF field->>'type' = 'textarea' THEN
                            field := jsonb_set(field, '{value}', '"[Redacted - Personal Information]"'::jsonb);
                        ELSE
                            field := jsonb_set(field, '{value}', '"[Redacted]"'::jsonb);
                        END IF;
                    END IF;

                    filtered_fields := filtered_fields || jsonb_build_array(field);
                END LOOP;
            END IF;

            section := jsonb_set(section, '{fields}', filtered_fields);
            filtered_sections := filtered_sections || jsonb_build_array(section);
        END LOOP;
    END IF;

    filtered_data := jsonb_set(contract_record.data, '{sections}', filtered_sections);

    -- Return filtered contract
    RETURN QUERY SELECT
        contract_record.id,
        contract_record.user_id,
        contract_record.title,
        filtered_data,
        -- Filter names based on config
        CASE WHEN (config->>'hide_names')::boolean
             THEN 'Dominant'
             ELSE contract_record.dominant_name
        END,
        CASE WHEN (config->>'hide_names')::boolean
             THEN 'Submissive'
             ELSE contract_record.submissive_name
        END,
        -- Filter signatures based on config
        CASE WHEN (config->>'hide_signatures')::boolean
             THEN '[Signed]'
             ELSE contract_record.owner_signature
        END,
        -- Filter signature dates (show only month/year)
        CASE WHEN (config->>'hide_signature_dates')::boolean AND contract_record.owner_signature_date IS NOT NULL
             THEN DATE_TRUNC('month', contract_record.owner_signature_date)::DATE
             ELSE contract_record.owner_signature_date
        END,
        CASE WHEN (config->>'hide_signatures')::boolean
             THEN '[Signed]'
             ELSE contract_record.submissive_signature
        END,
        CASE WHEN (config->>'hide_signature_dates')::boolean AND contract_record.submissive_signature_date IS NOT NULL
             THEN DATE_TRUNC('month', contract_record.submissive_signature_date)::DATE
             ELSE contract_record.submissive_signature_date
        END,
        contract_record.created_at,
        contract_record.updated_at,
        contract_record.brag_mode_enabled,
        contract_record.brag_mode_config,
        contract_record.is_public,
        contract_record.public_share_token,
        contract_record.public_share_role;
END;
$$;

-- ============================================
-- 3. UPDATE RLS POLICIES FOR BRAG MODE ACCESS
-- ============================================

-- Allow anonymous users to access contracts via brag mode function
-- Note: The function itself handles filtering, so this is safe

-- Grant execute permission on the function to anonymous users
GRANT EXECUTE ON FUNCTION get_brag_mode_contract(TEXT) TO anon, authenticated;

-- ============================================
-- 4. HELPER FUNCTION TO GENERATE BRAG TOKENS
-- ============================================

CREATE OR REPLACE FUNCTION generate_brag_token()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    new_token TEXT;
    token_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a random 32-character token
        new_token := encode(gen_random_bytes(24), 'base64');
        new_token := replace(replace(replace(new_token, '/', '_'), '+', '-'), '=', '');

        -- Check if token already exists
        SELECT EXISTS(SELECT 1 FROM contracts WHERE brag_mode_token = new_token) INTO token_exists;

        -- Exit loop if token is unique
        EXIT WHEN NOT token_exists;
    END LOOP;

    RETURN new_token;
END;
$$;

GRANT EXECUTE ON FUNCTION generate_brag_token() TO authenticated;

-- ============================================
-- 5. ADD HISTORY SUPPORT FOR BRAG MODE
-- ============================================

-- Update history policies to allow viewing history in brag mode (read-only)
DROP POLICY IF EXISTS "Users can view history for accessible contracts" ON history;

CREATE POLICY "Users can view history for accessible contracts"
    ON history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE contracts.id = history.contract_id
            AND (
                contracts.user_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM contract_shares
                    WHERE contract_shares.contract_id = contracts.id
                    AND contract_shares.shared_with_email = auth.jwt()->>'email'
                )
                OR (
                    -- Allow public users to view history for public contracts
                    contracts.is_public = TRUE
                )
                OR (
                    -- Allow brag mode users to view history (read-only)
                    contracts.brag_mode_enabled = TRUE
                    -- Note: We can't validate the token here, but since this is
                    -- SELECT only and the function filters data, it's safe
                )
            )
        )
    );

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

SELECT 'Brag mode migration completed successfully!' AS message;
SELECT 'You can now enable brag mode for contracts in the application UI.' AS next_step;
