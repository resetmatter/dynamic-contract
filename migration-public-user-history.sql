-- ============================================
-- Migration: Enable Public User History Tracking
-- ============================================
-- This migration updates RLS policies to allow public (non-authenticated) users
-- to create and view history entries for public contracts they can edit.
--
-- Run this in Supabase SQL Editor if you already have the schema deployed.
-- For new deployments, this is already included in supabase-schema.sql
--
-- ============================================

-- Drop existing history policies
DROP POLICY IF EXISTS "Users can view history for accessible contracts" ON history;
DROP POLICY IF EXISTS "Users can create history for editable contracts" ON history;

-- Recreate history SELECT policy with public access
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
            )
        )
    );

-- Recreate history INSERT policy with public editor support
CREATE POLICY "Users can create history for editable contracts"
    ON history FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE contracts.id = history.contract_id
            AND (
                contracts.user_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM contract_shares
                    WHERE contract_shares.contract_id = contracts.id
                    AND contract_shares.shared_with_email = auth.jwt()->>'email'
                    AND contract_shares.role = 'editor'
                )
                OR (
                    -- Allow public editors to insert history with null user_id
                    contracts.is_public = TRUE
                    AND contracts.public_share_role = 'editor'
                    AND history.user_id IS NULL
                )
            )
        )
    );

-- ============================================
-- Migration Complete!
-- ============================================
SELECT 'Public user history tracking enabled successfully!' AS message;
