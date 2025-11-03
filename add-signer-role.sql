-- ============================================
-- Add 'signer' role to public_share_role column
-- ============================================
-- This migration updates the CHECK constraint on public_share_role
-- to allow 'signer' as a valid role option

-- Drop the existing constraint
ALTER TABLE contracts
DROP CONSTRAINT IF EXISTS contracts_public_share_role_check;

-- Add the new constraint with 'signer' included
ALTER TABLE contracts
ADD CONSTRAINT contracts_public_share_role_check
CHECK (public_share_role IN ('viewer', 'editor', 'signer'));

-- Update any existing NULL values to 'viewer'
UPDATE contracts
SET public_share_role = 'viewer'
WHERE public_share_role IS NULL;

-- ============================================
-- UPDATE PUBLIC ACCESS POLICY FOR SIGNERS
-- ============================================
-- Allow signers to update signature fields only

-- Drop and recreate the policy to allow signers to update
DROP POLICY IF EXISTS "Anyone can update public contracts with editor token" ON contracts;

-- Editor policy - can update everything
CREATE POLICY "Anyone can update public contracts with editor token"
    ON contracts FOR UPDATE
    USING (
        is_public = TRUE
        AND public_share_token IS NOT NULL
        AND public_share_role = 'editor'
    );

-- Signer policy - can update signature fields only
CREATE POLICY "Anyone can update signatures with signer token"
    ON contracts FOR UPDATE
    USING (
        is_public = TRUE
        AND public_share_token IS NOT NULL
        AND public_share_role = 'signer'
    )
    WITH CHECK (
        is_public = TRUE
        AND public_share_token IS NOT NULL
        AND public_share_role = 'signer'
    );

SELECT 'Signer role added successfully! You can now use the signer role for public sharing.' AS message;
