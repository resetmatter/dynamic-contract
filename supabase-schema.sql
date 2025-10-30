-- ============================================
-- D/s Dynamic Contract - Supabase Schema
-- ============================================
-- This script creates all necessary tables and policies for the real-time contract editor
-- Run this in Supabase SQL Editor: Dashboard > SQL Editor > New Query

-- ============================================
-- 1. CONTRACTS TABLE
-- ============================================
-- Stores the main contract data with flexible JSONB structure

CREATE TABLE IF NOT EXISTS contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL DEFAULT 'Untitled Contract',
    data JSONB NOT NULL DEFAULT '{"sections": []}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS contracts_user_id_idx ON contracts(user_id);
CREATE INDEX IF NOT EXISTS contracts_updated_at_idx ON contracts(updated_at DESC);

-- ============================================
-- 2. CONTRACT SHARES TABLE
-- ============================================
-- Manages sharing contracts with partners

CREATE TABLE IF NOT EXISTS contract_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID REFERENCES contracts(id) ON DELETE CASCADE NOT NULL,
    shared_with_email TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('editor', 'viewer')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(contract_id, shared_with_email)
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS contract_shares_contract_id_idx ON contract_shares(contract_id);
CREATE INDEX IF NOT EXISTS contract_shares_email_idx ON contract_shares(shared_with_email);

-- ============================================
-- 3. HISTORY TABLE
-- ============================================
-- Tracks all changes and snapshots

CREATE TABLE IF NOT EXISTS history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID REFERENCES contracts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    change_type TEXT NOT NULL,
    description TEXT NOT NULL,
    snapshot JSONB,
    is_snapshot BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster timeline queries
CREATE INDEX IF NOT EXISTS history_contract_id_idx ON history(contract_id);
CREATE INDEX IF NOT EXISTS history_created_at_idx ON history(created_at DESC);
CREATE INDEX IF NOT EXISTS history_snapshots_idx ON history(contract_id, is_snapshot) WHERE is_snapshot = TRUE;

-- ============================================
-- 4. ROW LEVEL SECURITY POLICIES
-- ============================================
-- Enable RLS on all tables

ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE history ENABLE ROW LEVEL SECURITY;

-- ============================================
-- CONTRACTS POLICIES
-- ============================================

-- Users can view their own contracts
CREATE POLICY "Users can view own contracts"
    ON contracts FOR SELECT
    USING (auth.uid() = user_id);

-- Users can view contracts shared with them
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
-- CONTRACT SHARES POLICIES
-- ============================================

-- Users can view shares for their contracts
CREATE POLICY "Users can view shares for own contracts"
    ON contract_shares FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE contracts.id = contract_shares.contract_id
            AND contracts.user_id = auth.uid()
        )
    );

-- Users can view shares where they are the shared user
CREATE POLICY "Users can view own shares"
    ON contract_shares FOR SELECT
    USING (shared_with_email = auth.jwt()->>'email');

-- Users can create shares for their contracts
CREATE POLICY "Users can create shares for own contracts"
    ON contract_shares FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE contracts.id = contract_shares.contract_id
            AND contracts.user_id = auth.uid()
        )
    );

-- Users can delete shares for their contracts
CREATE POLICY "Users can delete shares for own contracts"
    ON contract_shares FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE contracts.id = contract_shares.contract_id
            AND contracts.user_id = auth.uid()
        )
    );

-- ============================================
-- HISTORY POLICIES
-- ============================================

-- Users can view history for contracts they have access to
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
            )
        )
    );

-- Users can insert history for contracts they can edit
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
            )
        )
    );

-- ============================================
-- 5. FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at on contracts
DROP TRIGGER IF EXISTS update_contracts_updated_at ON contracts;
CREATE TRIGGER update_contracts_updated_at
    BEFORE UPDATE ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. REALTIME PUBLICATION
-- ============================================
-- Enable realtime for all tables

-- Note: You still need to enable Realtime in the Supabase dashboard:
-- Go to Database > Replication > Enable for: contracts, contract_shares, history

-- This comment serves as a reminder to complete that step

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- Next steps:
-- 1. Enable Realtime replication in Supabase Dashboard (Database > Replication)
-- 2. Open index-realtime.html in your browser
-- 3. Create an account and start editing!

SELECT 'Schema created successfully! Remember to enable Realtime replication in the Supabase dashboard.' AS message;
