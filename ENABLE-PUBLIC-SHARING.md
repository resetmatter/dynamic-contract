# Enable Public Sharing Feature

This guide explains how to add public sharing capability to your dynamic contract application.

## What is Public Sharing?

Public sharing allows you to generate a unique, shareable link that anyone can view **without creating an account**. This is perfect for:
- Sharing contracts with partners who don't want to create an account
- Providing read-only access to contracts
- Quick previews without authentication barriers

## Setup Instructions

### 1. Run the SQL Migration

Open your Supabase dashboard and run the migration:

1. Go to **SQL Editor** in your Supabase dashboard
2. Click **New Query**
3. Copy and paste the contents of `add-public-sharing.sql`
4. Click **Run** to execute the migration

This will:
- Add `public_share_token` and `is_public` columns to the contracts table
- Create an index for fast public lookups
- Add RLS policy to allow public read access
- Create a helper function to generate secure tokens

### 2. Verify the Migration

After running the migration, you should see:
- ✅ "Public sharing feature added successfully!" message
- ✅ New columns in the contracts table
- ✅ New RLS policy for public access

### 3. How to Use Public Sharing

1. **Open a contract** in the editor
2. **Click the "🔗 Share" button** in the top toolbar
3. **Toggle "Enable public link"** in the Public Sharing section
4. **Copy the generated link** using the "📋 Copy" button
5. **Share the link** with anyone - they can view without logging in

### Security Notes

- Public links are **read-only** - viewers cannot edit
- Tokens are **cryptographically secure** random strings
- You can **disable public sharing** anytime by unchecking the toggle
- **Deleting a contract** automatically revokes all public links
- Public viewers see a **(Shared View)** label in the preview

### Example Public Link

```
https://yourdomain.com/index-realtime.html?share=AbC123XyZ...
```

When someone visits this link:
1. No login required
2. Contract opens directly in preview mode
3. Read-only access (cannot edit)
4. Clean, professional presentation

## Troubleshooting

### "Invalid or expired share link" error
- The contract may have been deleted
- Public sharing may have been disabled
- Check that the migration was applied correctly

### Public link not working
- Verify the migration ran successfully in Supabase
- Check browser console for errors
- Ensure RLS policies are enabled on the contracts table

### Cannot enable public sharing
- Make sure you're the contract owner (not a shared editor)
- Check that the migration added the required columns
- Verify your database connection

## Technical Details

**Database Changes:**
- `contracts.public_share_token` - Unique token for public access (TEXT, UNIQUE)
- `contracts.is_public` - Flag to enable/disable sharing (BOOLEAN, default FALSE)

**RLS Policy:**
- Anyone can SELECT contracts where `is_public = TRUE`
- App validates the token in the query WHERE clause

**Token Format:**
- 32-character base64-encoded random string
- URL-safe (/ → _, + → -, = removed)
- Collision-resistant (cryptographically random)

## Need Help?

If you encounter issues:
1. Check the browser console for errors
2. Verify the SQL migration completed successfully
3. Check Supabase logs for RLS policy errors
4. Ensure you're using the latest version of index-realtime.html
