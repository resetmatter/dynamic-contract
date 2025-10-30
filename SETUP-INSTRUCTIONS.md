# Setup Instructions - D/s Dynamic Contract Real-time Edition

This guide will walk you through setting up the real-time collaborative contract editor with Supabase.

## Prerequisites

- A web browser (Chrome, Firefox, Safari, or Edge)
- Internet connection
- Email address for account creation

## Step 1: Create Supabase Project (5 minutes)

If you already have a Supabase project, skip to Step 2.

1. **Go to Supabase**
   - Visit: https://supabase.com
   - Click "Start your project" or "Sign In"

2. **Create Account**
   - Sign in with GitHub, or
   - Create account with email

3. **Create New Project**
   - Click "New Project"
   - Choose your organization (or create one)
   - Fill in project details:
     - **Name**: `dynamic-contract` (or your choice)
     - **Database Password**: Create a strong password (save this!)
     - **Region**: Choose closest to your location
     - **Pricing Plan**: Free tier is fine
   - Click "Create new project"
   - Wait 2-3 minutes for project to be created

## Step 2: Get Your Supabase Credentials

1. **Open Project Settings**
   - Click the gear icon (⚙️) in the left sidebar
   - Select "API" from the settings menu

2. **Copy Your Credentials**
   You'll need two values:

   - **Project URL**
     - Looks like: `https://xxxxxxxxxxxxx.supabase.co`
     - Copy this URL

   - **anon public key**
     - A long string starting with `eyJ...`
     - Under "Project API keys" section
     - Copy the key labeled "anon" "public"

3. **Keep These Safe**
   - You'll paste these into the HTML file
   - Don't share them publicly!

## Step 3: Set Up Database Schema (3 minutes)

1. **Open SQL Editor**
   - In Supabase dashboard, click "SQL Editor" in left sidebar
   - Click "+ New query" button

2. **Run Schema Script**
   - Open `supabase-schema.sql` from this repository
   - Copy the entire contents
   - Paste into the SQL Editor
   - Click "Run" button (or press Ctrl/Cmd + Enter)

3. **Verify Success**
   - You should see: "Schema created successfully!"
   - Check "Database" > "Tables" in left sidebar
   - You should see three tables:
     - `contracts`
     - `contract_shares`
     - `history`

## Step 4: Enable Realtime (1 minute)

This is critical for real-time sync to work!

1. **Open Replication Settings**
   - Click "Database" in left sidebar
   - Click "Replication" tab

2. **Enable Realtime for Tables**
   - Find "contracts" table → Toggle the switch to **ON**
   - Find "contract_shares" table → Toggle the switch to **ON**
   - Find "history" table → Toggle the switch to **ON**

3. **Verify**
   - All three tables should show as enabled
   - You may see a brief "Applying changes..." message

## Step 5: Configure the HTML File (2 minutes)

Now we'll add your Supabase credentials to the app.

1. **Open the HTML File**
   - Open `index-realtime.html` in a text editor (VS Code, Sublime, Notepad++, etc.)

2. **Find the Configuration Section**
   - Press Ctrl/Cmd + F and search for: `SUPABASE_URL`
   - You'll find these lines around line 1983:

   ```javascript
   const SUPABASE_URL = 'https://sryxyqioytqxcmgtykao.supabase.co';
   const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```

3. **Replace with Your Credentials**
   - Replace the URL with your Project URL from Step 2
   - Replace the key with your anon public key from Step 2

   ```javascript
   const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
   const SUPABASE_ANON_KEY = 'your-long-anon-key-here';
   ```

4. **Save the File**
   - Save your changes (Ctrl/Cmd + S)

## Step 6: Open and Test (2 minutes)

1. **Open in Browser**
   - Double-click `index-realtime.html`
   - Or right-click → "Open with" → Your browser

2. **Create Account**
   - Click the "Sign Up" tab
   - Enter your email and a password (minimum 6 characters)
   - Enter your display name
   - Click "Create Account"

3. **Verify Email** (Important!)
   - Check your email inbox
   - Click the verification link from Supabase
   - Return to the app and login

4. **Start Creating**
   - After logging in, click "+ Create New Contract"
   - Start editing your contract!
   - Changes save automatically

## Step 7: Test Real-time Sync (Optional)

To test multi-tab sync:

1. **Open Second Tab**
   - Keep your current tab open
   - Open the same `index-realtime.html` in a new tab
   - You should be automatically logged in

2. **Edit in One Tab**
   - Make a change in one tab
   - Watch it appear in the other tab within 1-2 seconds

3. **Verify Sync Status**
   - Look for the "Synced" indicator
   - Both tabs should show "Synced"

## Troubleshooting

### "Failed to load contract"

**Problem**: Can't load contracts or see error messages

**Solutions**:
1. Check your internet connection
2. Verify Supabase URL and API key are correct in the HTML
3. Make sure you ran the schema script (Step 3)
4. Open browser console (F12) and check for errors

### "Changes not syncing"

**Problem**: Edits in one tab don't appear in another

**Solutions**:
1. Verify Realtime is enabled (Step 4) - this is the most common issue!
2. Check the sync indicator - should say "Synced"
3. Look for errors in browser console (F12 → Console tab)
4. Check Network tab (F12 → Network) for failed WebSocket (WS) connection

### "Can't login after signup"

**Problem**: Created account but can't login

**Solutions**:
1. Check your email for verification link
2. Click the verification link
3. Then try logging in again
4. If still failing, check Supabase dashboard → Authentication → Users

### "Shared contract not visible to partner"

**Problem**: Shared contract but partner can't see it

**Solutions**:
1. Make sure partner created account with the EXACT email you entered
2. Partner needs to refresh their contract list
3. Check the Shares list in the share dialog to verify it was created
4. Check Supabase dashboard → Database → contract_shares table

### Database errors

**Problem**: SQL errors or missing tables

**Solutions**:
1. Go to Supabase → Database → Tables
2. Verify all three tables exist (contracts, contract_shares, history)
3. If missing, re-run the schema script from Step 3
4. Check SQL Editor for error messages

### Still having issues?

1. **Check Browser Console**
   - Press F12
   - Go to Console tab
   - Look for red error messages
   - Copy the error and search for solutions

2. **Check Supabase Logs**
   - Go to Supabase dashboard
   - Click "Logs" in left sidebar
   - Check for errors

3. **Verify All Steps**
   - Go through each step above
   - Make sure nothing was skipped
   - Especially Step 4 (Enable Realtime)!

## Next Steps

Now that your app is set up:

1. **Create your first contract**
   - Click "Create New Contract"
   - Explore the default sections
   - Add your own sections and fields

2. **Share with your partner**
   - Click the Share button
   - Enter their email
   - Choose "Editor" role
   - They'll need to create an account first

3. **Use snapshots**
   - Make changes over time
   - Create snapshots at important milestones
   - View history to see all changes

4. **Explore features**
   - Try editing in multiple tabs
   - Check the history panel
   - Print a copy of your contract

## Security Notes

- Your Supabase credentials are in the HTML file - keep it secure
- Don't share your HTML file publicly if it contains your credentials
- For production use, consider environment variables
- All data is encrypted in transit (HTTPS/WSS)
- Row Level Security ensures users only see their own data

## What's Next?

Check out `README.md` for:
- Complete feature documentation
- Tips and best practices
- Customization options
- Roadmap for future features

Enjoy your real-time collaborative contract editor! ⛓️🎀
