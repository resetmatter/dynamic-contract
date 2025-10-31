-- ============================================
-- Migration: Add name and signature fields to contracts table
-- ============================================
-- Run this migration if you have an existing Supabase database
-- This adds the dominant_name, submissive_name, and signature fields

-- Add name fields
ALTER TABLE contracts
ADD COLUMN IF NOT EXISTS dominant_name TEXT DEFAULT 'Matthew',
ADD COLUMN IF NOT EXISTS submissive_name TEXT DEFAULT 'Shailah';

-- Add signature fields (if they don't exist)
ALTER TABLE contracts
ADD COLUMN IF NOT EXISTS owner_signature TEXT,
ADD COLUMN IF NOT EXISTS owner_signature_date DATE,
ADD COLUMN IF NOT EXISTS submissive_signature TEXT,
ADD COLUMN IF NOT EXISTS submissive_signature_date DATE;

-- Success message
SELECT 'Migration completed successfully! Name and signature fields added to contracts table.' AS message;
