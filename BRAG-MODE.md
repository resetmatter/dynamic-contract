# 🔒 Brag Mode Security Guide

## Overview

**Brag Mode** is a secure sharing feature that allows you to share your contract with others while keeping personal information private. Unlike CSS-based hiding, Brag Mode uses **server-side filtering** in PostgreSQL to ensure personal data never reaches viewers' browsers.

## 🛡️ Security Architecture

### Multi-Layer Security

1. **Database Layer**: Personal data is filtered in PostgreSQL before transmission
2. **Token-Based Access**: Separate brag tokens (different from regular share tokens)
3. **Server-Side Function**: `get_brag_mode_contract()` runs with security definer privileges
4. **Read-Only Access**: Brag mode links are always viewer-only
5. **Visual Indicators**: Clear UI feedback showing brag mode is active

### What Gets Hidden

When brag mode is enabled, you can choose what information to redact:

**Personal Information:**
- ✅ **Names**: Replaced with "Dominant" / "Submissive"
- ✅ **Signatures**: Replaced with "[Signed]"
- ✅ **Signature Dates**: Truncated to month/year only (day removed)

**Content Sections:**
- ✅ **Entire Sections**: Hide specific sections completely (e.g., "Hard Limits", "Punishments", "Daily Duties")
  - Select which sections to hide from a list of your contract sections
  - Hidden sections are completely removed server-side, not just blurred
  - Perfect for sharing the structure while keeping sensitive content private

**Future Features:**
- ⏳ **Custom Fields**: Mark individual fields as personal (coming soon)

### Security Guarantee

**The filtered data NEVER exists in the client's browser.** Even if someone:
- Inspects the DOM with DevTools
- Monitors network traffic
- Manipulates the URL parameters
- Modifies CSS or JavaScript

...they **cannot** access the original personal information because it was filtered in the database before being sent over the network.

## 📦 Setup Instructions

### Step 1: Run Database Migration

Before using brag mode, you must run the SQL migration to add the necessary database columns and functions.

1. Open your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy and paste the contents of `supabase-brag-mode-migration.sql`
5. Click **Run**

The migration will:
- Add `brag_mode_enabled`, `brag_mode_token`, and `brag_mode_config` columns to the `contracts` table
- Create the `get_brag_mode_contract()` PostgreSQL function for server-side filtering
- Create the `generate_brag_token()` helper function
- Update RLS policies to allow secure brag mode access
- Grant necessary permissions

### Step 2: Verify Migration

After running the migration, verify it completed successfully:

```sql
-- Check that new columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'contracts'
AND column_name IN ('brag_mode_enabled', 'brag_mode_token', 'brag_mode_config');

-- Check that functions were created
SELECT routine_name
FROM information_schema.routines
WHERE routine_name IN ('get_brag_mode_contract', 'generate_brag_token');
```

You should see 3 columns and 2 functions returned.

## 🎯 How to Use Brag Mode

### Enabling Brag Mode

1. Open a contract in the editor
2. Click the **Share** button
3. Scroll to the **✨ Brag Mode** section
4. Toggle **Enable Brag Mode**
5. Configure what to hide:

   **Personal Information:**
   - ☑️ Names (show "Dominant"/"Submissive" instead)
   - ☑️ Signatures (show "[Signed]" instead)
   - ☑️ Exact signature dates (show month/year only)

   **Sections to Hide:**
   - Select any sections you want to completely hide (e.g., "Hard Limits", "Safewords", "Punishments")
   - Hidden sections won't appear at all in the brag view
   - You can hide as many or as few sections as you want

6. Click **👁️ Preview Brag Mode** to see what others will see
7. Copy the brag mode link and share it!

### Sharing the Link

The brag mode link looks like:
```
https://your-app.com/index-realtime.html?brag=abc123xyz...
```

Anyone with this link can view your contract, but:
- Personal information is hidden
- They cannot edit anything (read-only)
- The original data never reaches their browser

### Previewing Before Sharing

Always use the **Preview Brag Mode** button before sharing to verify:
- Names are replaced with generic placeholders
- Signatures show "[Signed]" instead of actual text
- Dates show only month/year
- The overall contract still looks good

## 🔍 Technical Details

### Database Function

The `get_brag_mode_contract()` function:

```sql
CREATE OR REPLACE FUNCTION get_brag_mode_contract(brag_token TEXT)
RETURNS TABLE (...)
LANGUAGE plpgsql
SECURITY DEFINER
```

Key points:
- `SECURITY DEFINER`: Runs with elevated privileges to bypass RLS
- Validates the brag token before returning any data
- Filters data based on `brag_mode_config` settings
- Returns only if `brag_mode_enabled = TRUE`
- Uses JSONB operations to filter nested field data

### Configuration Storage

Brag mode settings are stored as JSONB in the `brag_mode_config` column:

```json
{
  "hide_names": true,
  "hide_signatures": true,
  "hide_signature_dates": true,
  "hidden_section_names": ["Hard Limits", "Safewords", "Punishments"],
  "personal_field_ids": []
}
```

**Configuration Fields:**
- `hide_names`: Replace names with "Dominant"/"Submissive"
- `hide_signatures`: Replace signatures with "[Signed]"
- `hide_signature_dates`: Truncate dates to month/year only
- `hidden_section_names`: Array of section titles to completely remove
- `personal_field_ids`: Reserved for future field-level filtering

### Client-Side Flow

1. User clicks brag mode link: `?brag=token123`
2. `checkAuth()` detects the brag token parameter
3. Calls `loadBragModeContract(token)`
4. Makes RPC call: `supabaseClient.rpc('get_brag_mode_contract', { brag_token: token })`
5. Receives filtered data from PostgreSQL
6. Displays in preview mode with brag mode banner
7. Original data never touches the client

## 🧪 Testing Security

### Recommended Tests

1. **DOM Inspection Test**
   - Open brag mode link
   - Open DevTools > Elements
   - Search for your actual name/signature
   - ✅ Should only find placeholders like "Dominant"

2. **Network Monitor Test**
   - Open brag mode link
   - Open DevTools > Network > WS (WebSocket)
   - Watch all network traffic
   - ✅ Original personal data should never appear in any payload

3. **URL Manipulation Test**
   - Try modifying the brag token in the URL
   - Try changing `?brag=` to `?share=`
   - ✅ Should show error or different filtered view

4. **JavaScript Console Test**
   ```javascript
   // In DevTools console
   console.log(currentContract.dominant_name);
   // Should show "Dominant", not your real name
   ```

5. **Source Code Test**
   - View page source
   - Search for your personal information
   - ✅ Should not find it in inline scripts or HTML

## 🚨 Security Considerations

### What Brag Mode Protects

✅ Names and personal identifiers
✅ Signatures
✅ Exact dates (truncated to month/year)
✅ Future: Custom marked fields

### What Brag Mode Does NOT Protect

❌ Contract content you've written (rules, duties, etc.)
❌ Section titles and structure
❌ File attachments (if implemented)
❌ Metadata like creation dates

**Important**: Review your contract content before enabling brag mode. Make sure the actual text of rules, limits, etc. doesn't contain personal information if you don't want it shared.

### Best Practices

1. **Always preview** before sharing the brag mode link
2. **Review contract content** for embedded personal info in rule text
3. **Use unique tokens** - never reuse or share your regular share tokens
4. **Disable when not needed** - turn off brag mode if you're not actively sharing
5. **Monitor usage** - check your Supabase logs for access patterns

## 🔧 Troubleshooting

### "Failed to load preview" Error

**Cause**: Database migration not run
**Solution**: Run `supabase-brag-mode-migration.sql` in Supabase SQL Editor

### "Invalid or expired brag mode link"

**Causes**:
1. Brag mode was disabled after link was shared
2. Contract was deleted
3. Token was regenerated

**Solution**: Re-enable brag mode and generate a new link

### Preview shows real data

**Cause**: Database function not filtering correctly
**Solutions**:
1. Check `brag_mode_config` in database
2. Verify checkboxes are checked in UI
3. Re-run migration to update function

### Token generation fails

**Cause**: PostgreSQL function not accessible
**Solutions**:
1. Check function permissions: `GRANT EXECUTE ON FUNCTION generate_brag_token() TO authenticated;`
2. App will fall back to client-side token generation

## 🔄 Future Enhancements

Planned features for brag mode:

- [ ] Mark individual fields as "personal" in the editor
- [ ] Watermark/timestamp on shared previews
- [ ] Access analytics (who viewed, when)
- [ ] Expiring brag links (time-limited access)
- [ ] Custom placeholder text instead of "Dominant"/"Submissive"
- [ ] Redaction of specific keywords across all fields
- [ ] PDF export with brag mode filtering

## 📚 Related Files

- `supabase-brag-mode-migration.sql` - Database migration script
- `index-realtime.html` - Main application with brag mode UI
- `BRAG-MODE.md` - This documentation file
- `supabase-schema.sql` - Base schema (run this first)

## 💡 Example Use Cases

### Scenario 1: Showing Off to Vanilla Friends

**Goal**: Share your D/s dynamic structure without revealing identities or super personal details.

1. Create your contract with all personal details
2. Enable brag mode with all privacy options checked
3. Hide sensitive sections like "Hard Limits", "Safewords", and "Punishments"
4. Preview to verify names are replaced and sensitive sections are gone
5. Share the brag link in your group chat
6. Friends see your contract structure without personal info! ✨

### Scenario 2: Sharing on Social Media

**Goal**: Post your contract to Reddit/Twitter without doxxing yourself.

1. Enable brag mode
2. Hide names, signatures, and dates
3. Hide sections like "Daily Duties", "Expectations", "Rewards" that might be too personal
4. Keep sections like "Introduction" and "Purpose" to show the framework
5. Preview to make sure nothing identifiable appears
6. Share screenshot or link publicly with confidence!

### Scenario 3: Showing Template to Other Couples

**Goal**: Help another couple get started with their own contract.

1. Enable brag mode
2. Replace your names with generic placeholders
3. Hide personal content sections but keep structural sections
4. They see your format and structure without your specific rules
5. They can use it as inspiration for their own contract!

---

**Questions or Issues?**
Open an issue on GitHub or check the Supabase logs for debugging information.
