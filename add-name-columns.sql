-- Migration: Add dominant_name and submissive_name columns to contracts table
-- Run this in your Supabase SQL Editor to add the missing columns

ALTER TABLE contracts
ADD COLUMN IF NOT EXISTS dominant_name TEXT DEFAULT 'Matthew',
ADD COLUMN IF NOT EXISTS submissive_name TEXT DEFAULT 'Shailah';

-- Verify columns were added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'contracts'
AND column_name IN ('dominant_name', 'submissive_name');
