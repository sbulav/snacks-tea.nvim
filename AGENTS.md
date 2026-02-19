# AGENTS.md

Guidelines for AI coding agents working on snacks-tea.nvim.

## Project Overview

snacks-tea.nvim is a Neovim plugin providing Forgejo/Gitea integration via the tea CLI.
It extends [snacks.nvim](https://github.com/folke/snacks.nvim), following its architecture closely.
The plugin wraps the [tea CLI](https://gitea.com/gitea/tea) for PR management.

## Requirements

- Neovim >= 0.9.4
- snacks.nvim (required dependency)
- tea CLI (external tool for Forgejo/Gitea API)

## Versioning

This project follows [Semantic Versioning](https://semver.org/). The version is defined in `lua/snacks/tea/init.lua` in `M.meta.version`.

When making changes:
- **MAJOR**: Breaking changes to public API
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

Update CHANGELOG.md for all changes following [Keep a Changelog](https://keepachangelog.com/) format.

## Build/Lint/Test Commands

This plugin uses plenary.nvim for testing. No automated CI is configured.

```bash
# Run all tests
nvim -l scripts/test.lua

# Run specific test file
nvim -l scripts/test.lua tests/item_spec.lua

# Run tests matching pattern
nvim -l scripts/test.lua tests/git_spec.lua

# Start Neovim with the plugin for manual testing
nvim --cmd "set rtp+=$(pwd)"

# In Neovim, test the plugin:
:lua Snacks.tea.pr()           " List PRs
:lua Snacks.tea.pr_create()    " Create PR
:TeaHealth                     " Check tea CLI availability

# Run luacheck if available
luacheck lua/

# Run stylua for formatting
stylua lua/
```

## Code Style Guidelines

### Formatting

- Use tabs for indentation (1 tab = 2 spaces displayed)
- Maximum line width: 120 characters
- Trailing commas in multi-line tables
- Single quotes for strings, double quotes only when needed

### Module Structure

```
lua/snacks/tea/
├── init.lua        # Main module, config, setup, public API
├── api.lua         # Tea CLI wrapper (async operations)
├── actions.lua     # User actions (checkout, review, merge, etc.)
├── buf.lua         # Buffer management for PR viewing
├── item.lua        # Data model for PRs (class with metatable)
├── git.lua         # Git utilities
├── types.lua       # LuaCATS type definitions
└── render/
    └── init.lua    # PR markdown rendering

lua/snacks/picker/
├── source/tea.lua  # Picker sources and finders
└── config/tea.lua  # Picker configurations
```

### Imports

```lua
-- Local modules at the top, capitalized
local Actions = require("snacks.tea.actions")
local Api = require("snacks.tea.api")
local Item = require("snacks.tea.item")

-- Standard library and vim after
local M = {}
```

### Type Annotations (LuaCATS)

All public APIs must have type annotations in `types.lua` or inline:

```lua
---@class snacks.tea.Config
---@field enabled? boolean
---@field tea? snacks.tea.tea.Config

---@param opts? snacks.picker.tea.Config
function M.pr(opts)
  -- ...
end
```

Use `---@type` for variable declarations:

```lua
---@type snacks.picker.tea.Item?
local item
```

### Naming Conventions

- **Modules**: `local M = {}` pattern, return M at end
- **Functions**: `snake_case` for public, `_private` prefix for internal
- **Tables/Objects**: `CamelCase` for class-like tables
- **Constants**: `UPPER_CASE` or `lower_case` for config tables
- **Local caches**: `cache`, `pr_cache`, etc.
- **Config tables**: `defaults` for module defaults

### Error Handling

Use `Snacks.notify.*` for user-facing messages:

```lua
Snacks.notify.error({ "Message", "Details" }, { title = "Title" })
Snacks.notify.warn("Warning message")
Snacks.notify.info("Info message")
```

For async operations, check for nil data:

```lua
Api.fetch(function(proc, data)
  if not data then
    return cb(nil)  -- Error already handled
  end
  -- process data
end, opts)
```

### Async Patterns

Use the snacks.picker async utilities:

```lua
local Async = require("snacks.picker.util.async")

-- Wrap sync function
local function wrap_sync(fn)
  return function(opts)
    local ret
    fn(function(_, data)
      ret = data
    end, opts):wait()
    return ret
  end
end
```

### Table Patterns

Use `vim.tbl_deep_extend("force", ...)` for merging configs:

```lua
local opts = vim.tbl_deep_extend("force", defaults, user_opts)
```

Use `vim.list_extend` for appending to arrays:

```lua
vim.list_extend(args, { "--option", value })
```

### Keymap Definitions

Follow the snacks.nvim keymap pattern:

```lua
keys = {
  select   = { "<cr>", "tea_actions", desc = "Select Action" },
  diff     = { "d",    "tea_diff",    desc = "View Diff" },
  refresh  = { "r",    function(item, buf)
    if buf and buf.update then buf:update() end
  end, desc = "Refresh" },
}
```

### Buffer Management

For tea:// protocol buffers:

```lua
-- Register BufReadCmd for tea:// scheme
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = "tea://*",
  callback = function(e)
    M.attach(e.buf)
  end,
})
```

### Avoid These Patterns

- Don't use `print()` - use `Snacks.notify` or `vim.notify`
- Don't hardcode paths - use `vim.fn.stdpath()` if needed
- Don't block the UI - use async operations via `Snacks.util.spawn`
- Don't mix GitHub and Forgejo concepts - this plugin is Forgejo/Gitea only

## Related Projects

- [snacks.nvim](https://github.com/folke/snacks.nvim) - Parent framework
- [snacks.gh](https://github.com/folke/snacks.nvim) - GitHub integration (reference implementation)
- [tea CLI](https://gitea.com/gitea/tea) - Forgejo/Gitea CLI tool

## Git Commit Style

Follow conventional commits:

```
feat: add PR template support
fix: correct branch detection for merge
docs: update configuration examples
refactor: extract comment parsing to separate function
```
