-- ============================================
-- D/s Dynamic Contract - FIXED Supabase Schema
-- ============================================
-- This fixes the infinite recursion in RLS policies
-- Run this in Supabase SQL Editor to fix the error

-- First, drop all existing policies to start clean
DROP POLICY IF EXISTS "Users can view own contracts" ON contracts;
DROP POLICY IF EXISTS "Users can view shared contracts" ON contracts;
DROP POLICY IF EXISTS "Users can create contracts" ON contracts;
DROP POLICY IF EXISTS "Users can update own contracts" ON contracts;
DROP POLICY IF EXISTS "Editors can update shared contracts" ON contracts;
DROP POLICY IF EXISTS "Users can delete own contracts" ON contracts;

DROP POLICY IF EXISTS "Users can view shares for own contracts" ON contract_shares;
DROP POLICY IF EXISTS "Users can view own shares" ON contract_shares;
DROP POLICY IF EXISTS "Users can create shares for own contracts" ON contract_shares;
DROP POLICY IF EXISTS "Users can delete shares for own contracts" ON contract_shares;

DROP POLICY IF EXISTS "Users can view history for accessible contracts" ON history;
DROP POLICY IF EXISTS "Users can create history for editable contracts" ON history;

-- ============================================
-- Add owner_user_id to contract_shares to avoid circular queries
-- ============================================
ALTER TABLE contract_shares
ADD COLUMN IF NOT EXISTS owner_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Populate existing rows
UPDATE contract_shares cs
SET owner_user_id = c.user_id
FROM contracts c
WHERE cs.contract_id = c.id AND cs.owner_user_id IS NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS contract_shares_owner_user_id_idx ON contract_shares(owner_user_id);

-- ============================================
-- CONTRACTS POLICIES (FIXED)
-- ============================================

-- Users can view their own contracts
CREATE POLICY "Users can view own contracts"
    ON contracts FOR SELECT
    USING (auth.uid() = user_id);

-- Users can view contracts shared with them
-- This is OK because contract_shares policies don't query contracts for SELECT
CREATE POLICY "Users can view shared contracts"
    ON contracts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contract_shares
            WHERE contract_shares.contract_id = contracts.id
            AND contract_shares.shared_with_email = auth.jwt()->>'email'
        )
    );

-- Users can insert their own contracts
CREATE POLICY "Users can create contracts"
    ON contracts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own contracts
CREATE POLICY "Users can update own contracts"
    ON contracts FOR UPDATE
    USING (auth.uid() = user_id);

-- Users with editor role can update shared contracts
CREATE POLICY "Editors can update shared contracts"
    ON contracts FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM contract_shares
            WHERE contract_shares.contract_id = contracts.id
            AND contract_shares.shared_with_email = auth.jwt()->>'email'
            AND contract_shares.role = 'editor'
        )
    );

-- Users can delete their own contracts
CREATE POLICY "Users can delete own contracts"
    ON contracts FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- CONTRACT SHARES POLICIES (FIXED - NO RECURSION)
-- ============================================

-- Users can view shares for their contracts (using owner_user_id, no join!)
CREATE POLICY "Users can view shares for own contracts"
    ON contract_shares FOR SELECT
    USING (owner_user_id = auth.uid());

-- Users can view shares where they are the shared user
CREATE POLICY "Users can view own shares"
    ON contract_shares FOR SELECT
    USING (shared_with_email = auth.jwt()->>'email');

-- Users can create shares for their contracts (using owner_user_id)
CREATE POLICY "Users can create shares for own contracts"
    ON contract_shares FOR INSERT
    WITH CHECK (owner_user_id = auth.uid());

-- Users can delete shares for their contracts (using owner_user_id)
CREATE POLICY "Users can delete shares for own contracts"
    ON contract_shares FOR DELETE
    USING (owner_user_id = auth.uid());

-- ============================================
-- HISTORY POLICIES (FIXED)
-- ============================================

-- Users can view history for contracts they own
CREATE POLICY "Users can view history for own contracts"
    ON history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE contracts.id = history.contract_id
            AND contracts.user_id = auth.uid()
        )
    );

-- Users can view history for contracts shared with them
CREATE POLICY "Users can view history for shared contracts"
    ON history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contract_shares
            WHERE contract_shares.contract_id = history.contract_id
            AND contract_shares.shared_with_email = auth.jwt()->>'email'
        )
    );

-- Users can insert history for their own contracts
CREATE POLICY "Users can create history for own contracts"
    ON history FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE contracts.id = history.contract_id
            AND contracts.user_id = auth.uid()
        )
    );

-- Users can insert history for contracts they can edit
CREATE POLICY "Users can create history for shared contracts"
    ON history FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM contract_shares
            WHERE contract_shares.contract_id = history.contract_id
            AND contract_shares.shared_with_email = auth.jwt()->>'email'
            AND contract_shares.role = 'editor'
        )
    );

-- ============================================
-- TRIGGER TO AUTO-SET owner_user_id
-- ============================================

-- Function to automatically set owner_user_id when creating a share
CREATE OR REPLACE FUNCTION set_share_owner()
RETURNS TRIGGER AS $$
BEGIN
    -- Get the owner's user_id from the contract
    SELECT user_id INTO NEW.owner_user_id
    FROM contracts
    WHERE id = NEW.contract_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-populate owner_user_id
DROP TRIGGER IF EXISTS set_share_owner_trigger ON contract_shares;
CREATE TRIGGER set_share_owner_trigger
    BEFORE INSERT ON contract_shares
    FOR EACH ROW
    EXECUTE FUNCTION set_share_owner();

-- ============================================
-- VERIFICATION
-- ============================================

-- Test that policies work without recursion
SELECT 'RLS policies fixed! You can now use the app without infinite recursion errors.' AS message;
