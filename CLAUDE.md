# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a single-page HTML application for creating customizable D/s dynamic contracts. The repository contains two main HTML files that are self-contained with embedded CSS and JavaScript.

## File Structure

- **contract.html** - The main contract template (52KB)
  - Interactive form for creating D/s dynamic contracts
  - Self-contained with embedded CSS (dark red/pink theme with chains and bows)
  - Vanilla JavaScript for form handling, drag-and-drop, and localStorage persistence

- **covenant-template.html** - Alternative covenant template (437KB)
  - Larger file with embedded base64 background images
  - Similar structure but different visual styling

## Architecture

Both files follow a monolithic HTML structure:
1. HTML structure with semantic sections (Parties, Commands, Duties, Boundaries, Discipline, Terms)
2. Embedded `<style>` tags containing all CSS
3. Embedded `<script>` tags containing all JavaScript functionality

### Key JavaScript Features

**Data Persistence** (contract.html)
- Auto-save functionality using localStorage
- Saves form state every 500ms after input changes
- Stores: rules, hard/soft limits, safewords, rewards, punishments, daily duties, expectations
- Load saved data on page load

**Dynamic Content Management**
- Add/remove form fields dynamically
- Drag-and-drop reordering of list items
- Smooth scroll animations when adding new items
- Visual feedback during drag operations

**Key Functions** (contract.html)
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

Since this is a standalone HTML application with no dependencies:
- No test framework
- Manual testing by opening in browser
- Test localStorage by inspecting browser DevTools > Application > Local Storage
- Test print layout using browser print preview
