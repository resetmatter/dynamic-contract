# D/s Dynamic Contract - Real-time Edition

A collaborative, real-time contract editor built for D/s relationships with automatic syncing, version history, and multi-device support.

## ✨ Features

### Core Features
- **Real-time Sync**: Changes sync instantly across all devices and tabs
- **Multi-user Collaboration**: Share contracts with your partner with editor or viewer permissions
- **Automatic History**: Every change is tracked automatically
- **Manual Snapshots**: Save important milestones and restore them later
- **Presence Indicators**: See who's online and editing
- **Secure Authentication**: Email/password login with Supabase Auth
- **Offline Support**: Continue editing offline, syncs when reconnected

### Contract Features
- **Flexible Sections**: Add, remove, and customize sections as needed
- **Multiple Field Types**: Text inputs, textareas, and list items
- **Drag & Drop**: Reorder list items easily
- **Auto-save**: Changes save automatically every 500ms
- **Print-friendly**: Clean print layout for physical copies
- **Beautiful UI**: Dark red/pink theme with chains and bows

## 🚀 Quick Start

### Step 1: Set Up Supabase Database

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **SQL Editor** (left sidebar)
4. Copy and paste the contents of `supabase-schema.sql`
5. Click **Run** to create all tables

### Step 2: Enable Realtime

1. In Supabase, go to **Database** → **Replication**
2. Find these tables and enable realtime for each:
   - `contracts`
   - `contract_shares`
   - `history`
3. Toggle the switch to enable replication

### Step 3: Open the Application

1. Open `index-realtime.html` in your web browser
2. Create an account or login
3. Start creating your contract!

That's it! Your real-time contract editor is ready to use.

## 📖 Detailed Setup Guide

See `SETUP-INSTRUCTIONS.md` for a step-by-step guide with screenshots and troubleshooting.

## 🎯 How to Use

### Creating Your First Contract

1. **Login/Signup**: Create an account with your email
2. **Create Contract**: Click "Create New Contract" on the dashboard
3. **Edit Title**: Click the title at the top to rename your contract
4. **Add Sections**: Default sections are created automatically, or click "+ Add Section"
5. **Add Fields**: Click "+ Add Field" in any section
6. **Edit Content**: Click on any field to edit
7. **Auto-save**: Changes save automatically - watch the "Synced" indicator

### Sharing with Your Partner

1. Open a contract
2. Click **🔗 Share** button
3. Enter your partner's email address
4. Choose their role:
   - **Editor**: Can make changes
   - **Viewer**: Read-only access
5. Click **Share**

Your partner will need to create an account with that email to access the contract.

### Using History & Snapshots

**Automatic History**:
- Every save is tracked automatically
- Click **📜 History** to see all changes
- View who made what changes and when

**Manual Snapshots**:
- Click **📸 Snapshot** to save a milestone
- Add a description (e.g., "Final version agreed upon")
- Restore any snapshot later from the history panel

### Multi-Tab/Multi-Device Sync

1. Open the same contract in multiple browser tabs
2. Or open on your phone and computer
3. Edit in one place, see changes appear instantly in the other
4. The "Synced" indicator shows sync status

## 🏗️ Architecture

### Database Schema

```
contracts
├── id (uuid, primary key)
├── user_id (uuid, foreign key to auth.users)
├── title (text)
├── data (jsonb) - flexible contract structure
├── created_at (timestamp)
└── updated_at (timestamp)

contract_shares
├── id (uuid, primary key)
├── contract_id (uuid, foreign key)
├── shared_with_email (text)
├── role (text: 'editor' | 'viewer')
└── created_at (timestamp)

history
├── id (uuid, primary key)
├── contract_id (uuid, foreign key)
├── user_id (uuid, foreign key)
├── change_type (text)
├── description (text)
├── snapshot (jsonb) - full contract data at this point
├── is_snapshot (boolean)
└── created_at (timestamp)
```

### File Structure

```
dynamic-contract/
├── index-realtime.html       # Main application (NEW)
├── index.html                 # Original version (backup)
├── covenant-template.html     # Alternative template
├── supabase-schema.sql       # Database setup script
├── SETUP-INSTRUCTIONS.md     # Detailed setup guide
├── README.md                 # This file
└── CLAUDE.md                 # Development notes
```

## 🔒 Security

### Row Level Security (RLS)

All tables use Supabase RLS policies:

**Contracts**:
- Users can only read/write their own contracts
- Shared contracts can be read by shared users
- Only editors can modify shared contracts

**Contract Shares**:
- Users can only manage shares for their contracts

**History**:
- Users can read history for contracts they have access to
- History is automatically created (users don't write directly)

### Data Privacy

- All data is stored in your Supabase project
- Supabase uses encryption at rest and in transit
- Your credentials (URL, API key) are embedded in the HTML
  - Keep the HTML file secure
  - Don't commit credentials to public repositories
  - For production, move credentials to environment variables

## 🛠️ Customization

### Adding New Section Types

Edit the `renderSection()` function in `index-realtime.html`:

```javascript
const defaultSections = [
    { type: 'custom', title: 'Your New Section', fields: [] },
    // ... more sections
];
```

### Changing Colors/Theme

Edit CSS variables at the top of `<style>`:

```css
:root {
    --primary-dark: #8b0000;
    --primary-light: #dc143c;
    --accent-pink: #ff69b4;
    /* ... more colors */
}
```

### Adding New Field Types

Edit the `renderField()` function and add your type:

```javascript
const fieldTypes = {
    text: (f) => `<input type="text" value="${f.value || ''}">`,
    textarea: (f) => `<textarea>${f.value || ''}</textarea>`,
    // Add your custom type here
    mytype: (f) => `<div>Your custom HTML</div>`
};
```

## 🐛 Troubleshooting

### "Failed to load contract"

- Check your internet connection
- Verify Supabase URL and API key are correct
- Check browser console for errors (F12 → Console)

### "Changes not syncing"

- Ensure Realtime is enabled in Supabase (see Step 2 above)
- Check the sync indicator - it should say "Synced"
- Try refreshing the page
- Check browser console for WebSocket errors

### "Can't share with partner"

- Make sure they created an account with the exact email you entered
- Check the Shares list to verify the share was created
- They need to refresh their contract list to see shared contracts

### "Database errors"

- Verify you ran the complete `supabase-schema.sql` script
- Check Supabase dashboard → Database → Tables to see if all tables exist
- Look at the SQL logs in Supabase for detailed errors

## 🔄 Migration from Old Version

If you have data in `index.html` (localStorage or Gist):

### Option 1: Manual Copy/Paste
1. Open old `index.html`, copy all content
2. Create new contract in `index-realtime.html`
3. Paste content into corresponding fields

### Option 2: Export/Import (Future Feature)
We can build an import tool that reads localStorage and creates contracts in Supabase. Let me know if you need this!

## 📱 Mobile Support

The application is fully responsive:
- Touch-friendly buttons
- Mobile-optimized layout
- Collapsible sections on small screens
- Full-screen history panel on mobile

## 🚧 Known Limitations

1. **Email Verification**: Supabase sends verification emails - users must verify before full access
2. **Concurrent Editing**: Last write wins - no merge conflict resolution yet
3. **File Size**: Very large contracts (1000+ fields) may be slow
4. **Browser Support**: Requires modern browser with ES6+ support

## 🗺️ Roadmap

### Phase 1: Core Features ✅ (Current Release)
- [x] User authentication
- [x] Real-time sync
- [x] Contract CRUD
- [x] Basic sharing
- [x] History tracking
- [x] Manual snapshots

### Phase 2: Enhanced Collaboration (Next)
- [ ] Field-level editing indicators
- [ ] Conflict resolution UI
- [ ] Comments/annotations
- [ ] Email notifications for changes
- [ ] Activity feed

### Phase 3: Advanced Features (Future)
- [ ] Template library
- [ ] Export to PDF
- [ ] Custom themes
- [ ] Mobile app
- [ ] AI-assisted contract writing

## 💡 Tips & Best Practices

1. **Use Snapshots**: Create snapshots before major changes
2. **Descriptive Names**: Use clear section and field names
3. **Regular Sync**: Keep browser tabs open to stay synced
4. **Test Sharing**: Test with a second account before sharing with partner
5. **Backup**: Periodically export/screenshot important contracts

## 🤝 Support

- **Issues**: Check the troubleshooting section above
- **Questions**: Review `SETUP-INSTRUCTIONS.md` for detailed steps
- **Feature Requests**: Keep a list of desired features

## 📄 License

This is a personal project. Use freely for personal relationships. Not for commercial use.

## 🙏 Credits

Built with:
- [Supabase](https://supabase.com) - Backend and real-time sync
- [Google Fonts](https://fonts.google.com) - Cinzel & Crimson Text fonts
- Lots of love and dedication to healthy D/s relationships ⛓️🎀

---

**Remember**: A contract is only as strong as the communication and trust behind it. This tool is here to help organize your dynamic, but the real work happens between you and your partner. 💕
