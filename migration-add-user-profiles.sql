-- ============================================
-- Migration: Add User Profiles Table
-- ============================================
-- This migration adds the user_profiles table to an existing database
-- Run this in Supabase SQL Editor if you already have contracts/shares/history tables

-- ============================================
-- 1. CREATE USER PROFILES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS user_profiles_id_idx ON user_profiles(id);

-- ============================================
-- 2. ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. CREATE RLS POLICIES
-- ============================================

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Anyone can view profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can create own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON user_profiles;

-- Users can view all profiles (for presence/display names)
CREATE POLICY "Anyone can view profiles"
    ON user_profiles FOR SELECT
    USING (true);

-- Users can only insert their own profile
CREATE POLICY "Users can create own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = id);

-- Users can only delete their own profile
CREATE POLICY "Users can delete own profile"
    ON user_profiles FOR DELETE
    USING (auth.uid() = id);

-- ============================================
-- 4. CREATE TRIGGER FOR UPDATED_AT
-- ============================================

-- The update_updated_at_column function should already exist
-- If not, uncomment the following:

-- CREATE OR REPLACE FUNCTION update_updated_at_column()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     NEW.updated_at = NOW();
--     RETURN NEW;
-- END;
-- $$ language 'plpgsql';

-- Trigger to auto-update updated_at on user_profiles
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. VERIFY SETUP
-- ============================================

SELECT
    'user_profiles table created successfully!' AS status,
    COUNT(*) AS existing_profiles
FROM user_profiles;

-- ============================================
-- NEXT STEPS:
-- ============================================
-- 1. Go to Supabase Dashboard > Database > Replication
-- 2. Enable Realtime for the 'user_profiles' table
-- 3. Refresh your app - the user_profiles table should now work!
