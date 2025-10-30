-- ============================================
-- Add Public Sharing Feature
-- ============================================
-- This migration adds the ability to share contracts publicly via a unique link
-- without requiring the recipient to have an account

-- Add public sharing columns to contracts table
ALTER TABLE contracts
ADD COLUMN IF NOT EXISTS public_share_token TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT FALSE;

-- Index for fast public lookups by token
CREATE INDEX IF NOT EXISTS contracts_public_token_idx ON contracts(public_share_token) WHERE is_public = TRUE;

-- ============================================
-- PUBLIC ACCESS POLICY
-- ============================================
-- Allow anyone to view contracts that are publicly shared via valid token

CREATE POLICY "Anyone can view public contracts with valid token"
    ON contracts FOR SELECT
    USING (
        is_public = TRUE
        AND public_share_token IS NOT NULL
    );

-- Note: The app will validate the token in the WHERE clause of the query
-- This policy just enables public access to public contracts

-- ============================================
-- Function to generate unique share token
-- ============================================
CREATE OR REPLACE FUNCTION generate_share_token()
RETURNS TEXT AS $$
DECLARE
    token TEXT;
    exists_check BOOLEAN;
BEGIN
    LOOP
        -- Generate a random 32-character token
        token := encode(gen_random_bytes(24), 'base64');
        -- Remove characters that might cause URL issues
        token := replace(replace(replace(token, '/', '_'), '+', '-'), '=', '');

        -- Check if token already exists
        SELECT EXISTS(SELECT 1 FROM contracts WHERE public_share_token = token) INTO exists_check;

        -- Exit loop if unique
        EXIT WHEN NOT exists_check;
    END LOOP;

    RETURN token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT 'Public sharing feature added successfully!' AS message;
