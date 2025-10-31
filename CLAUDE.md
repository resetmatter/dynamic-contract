# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a single-page HTML application for creating customizable D/s dynamic contracts. The repository contains two main HTML files that are self-contained with embedded CSS and JavaScript.

## File Structure

- **index-realtime.html** - Real-time collaborative edition (NEW, recommended)
  - Full-featured contract editor with Supabase backend
  - Real-time multi-device/multi-user sync
  - User authentication, sharing, and history tracking
  - Self-contained with embedded CSS and JavaScript
  - Requires Supabase project setup (see SETUP-INSTRUCTIONS.md)

- **index.html** - Main contract template with GitHub Gist sync
  - Interactive form for creating D/s dynamic contracts
  - Self-contained with embedded CSS (dark red/pink theme with chains and bows)
  - Vanilla JavaScript for form handling, drag-and-drop, and localStorage persistence
  - Optional GitHub Gist integration for backup/sharing

- **covenant-template.html** - Alternative covenant template (437KB)
  - Larger file with embedded base64 background images
  - Similar structure but different visual styling

- **supabase-schema.sql** - Database schema for real-time edition
  - Creates contracts, contract_shares, and history tables
  - Includes Row Level Security (RLS) policies
  - Run in Supabase SQL Editor to set up backend

- **SETUP-INSTRUCTIONS.md** - Step-by-step setup guide for real-time edition
- **README.md** - Complete documentation and user guide

## Architecture

### Real-time Edition (index-realtime.html)

**Stack:**
- Frontend: Self-contained HTML with vanilla JavaScript
- Backend: Supabase (PostgreSQL + Realtime + Auth)
- Real-time: Supabase Realtime (WebSocket-based)

**Database Schema:**
- `contracts` - Main contract data (JSONB for flexible structure)
- `contract_shares` - Sharing permissions (email-based, role: editor/viewer)
- `history` - Change tracking and snapshots

**Key Features:**
1. **Authentication** - Supabase Auth with email/password
2. **Real-time Sync** - PostgreSQL changes broadcast via WebSocket
3. **Presence System** - Track who's online using Supabase Presence
4. **History Tracking** - Automatic change log + manual snapshots
5. **Row Level Security** - Postgres RLS policies for data security

**Key JavaScript Functions (index-realtime.html):**
- `checkAuth()` - Verify user session on load
- `saveContract()` - Debounced save to Supabase (500ms)
- `setupRealtimeSync()` - Subscribe to database changes
- `handleRealtimeUpdate()` - Handle incoming sync updates
- `trackChange()` - Log changes to history table
- `setupPresence()` - Initialize presence tracking
- `renderContractEditor()` - Dynamic section/field rendering

### Original Edition (index.html)

Monolithic HTML structure:
1. HTML structure with semantic sections (Parties, Commands, Duties, Boundaries, Discipline, Terms)
2. Embedded `<style>` tags containing all CSS
3. Embedded `<script>` tags containing all JavaScript functionality

**Data Persistence** (localStorage + GitHub Gist)
- Auto-save functionality using localStorage
- Saves form state every 500ms after input changes
- Stores: rules, hard/soft limits, safewords, rewards, punishments, daily duties, expectations
- Load saved data on page load
- Optional GitHub Gist backup for sharing

**Dynamic Content Management**
- Add/remove form fields dynamically
- Drag-and-drop reordering of list items
- Smooth scroll animations when adding new items
- Visual feedback during drag operations

**Key Functions (index.html):**
- `autoSave()` - Serializes form data to localStorage
- `loadSavedData()` - Restores form state from localStorage
- `addRule()`, `addHardLimit()`, `addSoftLimit()`, etc. - Add new form fields
- `initDragAndDrop()` - Enables drag-and-drop for list items
- Drag handlers: `handleDragStart()`, `handleDrop()`, etc.

## Development Notes

- No build process required - these are static HTML files
- Open directly in browser to view/edit
- To test: Simply open the HTML file in a web browser
- localStorage data persists between sessions (key: 'contractData')
- Print styles are defined for PDF generation (@media print rules)

## Styling

The visual theme uses:
- Dark red/crimson color scheme (#8b0000, #dc143c)
- Pink accents (#ff69b4, #ffb6c1)
- Custom fonts: 'Cinzel' for headers, 'Crimson Text' for body
- Decorative elements: chain borders, pink bow emojis (🎀), chains (⛓️)
- Leather texture overlays with gradients
- Responsive design with mobile breakpoints

## Testing

### Real-time Edition (index-realtime.html)
- Requires Supabase backend setup (see SETUP-INSTRUCTIONS.md)
- Manual testing by opening in browser after database setup
- Test authentication: Create account, login, logout
- Test real-time sync: Open in multiple tabs, edit in one, verify sync in others
- Test sharing: Share contract with another test account
- Test history: Make changes, verify they appear in history panel
- Test snapshots: Create snapshot, make changes, restore snapshot
- Inspect browser DevTools > Console for errors
- Inspect Network tab > WS for WebSocket connection

### Original Edition (index.html)
- No test framework
- Manual testing by opening in browser
- Test localStorage by inspecting browser DevTools > Application > Local Storage
- Test GitHub Gist integration (if configured)
- Test print layout using browser print preview
