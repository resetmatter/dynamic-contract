# Update Real-time App to Match Original Design

## Changes Needed

### 1. Preview CSS Updates
- Add leather texture overlay
- Use original color scheme (dark red/pink)
- Add pink glow effects
- Style sections with gradients and borders
- Add decorative divider styling

### 2. Preview Content
- Add pink bows (🎀) in corners
- Add chain/bow dividers (⛓️ 🎀 ⛓️) between sections
- Use original typography and spacing
- Match section header styling

### 3. Default Sections
Current sections:
- The Parties
- Purpose & Philosophy
- Rules & Commands
- Duties & Expectations
- Boundaries & Limits
- Discipline & Rewards
- Terms & Conditions

Should match original:
- Parties (Dom and Sub)
- Commands & Absolute Rules
- Required Duties & Service
- Boundaries (Hard Limits, Soft Limits, Safewords)
- Discipline & Correction (Punishments, Rewards)
- Terms of Ownership (Contract terms, termination, renegotiation)

### 4. Field Structure
- Each section should have pre-defined fields
- Use original placeholders
- Match original field types and labels

## Implementation Plan

1. Update preview CSS to match original dark theme
2. Add decorative elements (bows, chains) to preview
3. Update renderPreview() to include dividers
4. Update default sections in renderContractEditor()
5. Add original color variables
6. Test preview matches original look

## Files to Modify

- `index-realtime.html` - All changes in one file
  - CSS section (lines ~11-872)
  - renderPreview() function (lines ~1766-1811)
  - Default sections (lines ~1297-1312)
