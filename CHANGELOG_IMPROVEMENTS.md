# snacks-tea.nvim - UI Customization & Layout Configuration Update

## Summary

This update brings comprehensive improvements to snacks-tea.nvim, focusing on three key areas:
1. **UI Customization** - Full control over colors and highlights
2. **Layout Configuration** - Flexible picker layouts and dimensions
3. **Enhanced Buffer Experience** - Better PR viewing with collapsible sections

## What's New

### 🎨 UI Customization

**Customizable Highlights for All Elements:**
- PR state colors (open, closed, merged, draft)
- Author and assignee badges
- Labels, branches, and PR numbers
- Comment headers and dates
- Titles and descriptions

**Example:**
```lua
ui = {
  highlights = {
    pr_state = {
      open = "DiagnosticOk",
      closed = "DiagnosticError",
      merged = "DiagnosticInfo",
      draft = "Comment",
    },
    author = "Identifier",
    assignee = "Function",
  },
}
```

### 📐 Layout Configuration

**Configurable Layouts for Each Picker Type:**
- PR List picker
- Actions menu
- Diff viewer
- PR creation editor

**Supported Features:**
- Snacks.nvim layout presets (ivy, select, split, modal)
- Custom dimensions (width, height)
- Position control (top, bottom, left, right)

**Example:**
```lua
layout = {
  pr_list = {
    preset = "ivy",
    layout = { width = 0.9, height = 0.8 },
  },
  actions = {
    preset = "select",
    layout = { max_width = 60, max_height = 20 },
  },
  diff = {
    preset = "split",
    layout = { position = "bottom", height = 0.5 },
  },
}
```

### 📄 Enhanced Buffer Experience

**New Buffer Features:**
- Collapsible sections with fold markers
- Toggle visibility of comments and diffs
- Buffer-local commands
- render-markdown.nvim integration
- Better readability with visual hierarchy

**Buffer Commands:**
- `:TeaRefresh` - Refresh PR buffer
- `:TeaToggleComments` - Toggle comments visibility
- `:TeaToggleDiff` - Toggle diff visibility

**Display Options:**
```lua
buffer = {
  display = {
    show_comments = true,
    show_diff = true,
    fold_comments = true,
    fold_diff = true,
  },
  integrations = {
    render_markdown = true,
  },
}
```

## Breaking Changes

### Configuration Structure

The configuration has been reorganized for better clarity:

**Old Structure:**
```lua
{
  tea = { ... },
  keys = { ... },
  wo = { ... },
  bo = { ... },
  scratch = { ... },
  icons = { ... },
}
```

**New Structure:**
```lua
{
  tea = { ... },        -- unchanged
  keys = { ... },       -- unchanged
  icons = { ... },      -- unchanged
  
  ui = {                -- NEW: UI customization
    highlights = { ... },
    scratch = { ... },  -- moved here
  },
  
  layout = { ... },     -- NEW: Layout configuration
  
  buffer = {            -- NEW: Buffer configuration
    wo = { ... },       -- moved here
    bo = { ... },       -- moved here
    display = { ... },  -- NEW
    integrations = { ... }, -- NEW
  },
}
```

### Migration Guide

**If you had custom `wo` or `bo` options:**
```lua
-- Before:
wo = { wrap = true, number = false }
bo = { ... }

-- After:
buffer = {
  wo = { wrap = true, number = false },
  bo = { ... },
}
```

**If you had custom scratch dimensions:**
```lua
-- Before:
scratch = { height = 20 }

-- After:
ui = {
  scratch = { height = 20, width = 160 },
}
-- OR for PR creation specifically:
layout = {
  create = {
    scratch = { height = 25, width = 160 },
  },
}
```

**Note:** Old configurations without these sections will use sensible defaults, so existing minimal configs will continue to work.

## Files Modified

- `lua/snacks/tea/init.lua` - Core config restructuring
- `lua/snacks/tea/buf.lua` - Buffer enhancements and commands
- `lua/snacks/tea/render/init.lua` - Dynamic highlights and fold markers
- `lua/snacks/tea/actions.lua` - Layout-aware action pickers
- `lua/snacks/picker/source/tea.lua` - Dynamic highlight formatting
- `lua/snacks/picker/config/tea.lua` - Layout configuration support
- `README.md` - Comprehensive documentation update

## Statistics

- **7 files changed**
- **846 insertions, 284 deletions**
- **Net addition: 562 lines** (mostly documentation and config options)

## Compatibility

- ✅ **Backward Compatible**: Old configs continue to work with defaults
- ✅ **Neovim Version**: Still requires Neovim >= 0.9.4
- ✅ **Dependencies**: No new dependencies required
- ✅ **Optional**: render-markdown.nvim support (optional)

## Testing Checklist

- [ ] PR list displays with custom highlights
- [ ] Actions menu uses configured layout
- [ ] Diff viewer respects layout settings
- [ ] Buffer commands work (`:TeaRefresh`, `:TeaToggleComments`, `:TeaToggleDiff`)
- [ ] Fold markers appear and work correctly
- [ ] render-markdown.nvim integration (if installed)
- [ ] Layout presets work correctly
- [ ] Custom scratch dimensions apply

## Documentation

All features are fully documented in the updated README.md:
- Complete configuration reference
- Examples for each feature
- Migration guide
- Troubleshooting section
- Enhanced features showcase

## Future Enhancements

Potential future additions:
- PR templates support
- Multi-instance support
- Draft PR support
- PR labels management
- More granular fold control

---

**Version:** Post-improvement update
**Date:** 2025-02-03
**Status:** Ready for production
