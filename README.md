# snacks-tea.nvim

A Forgejo/Gitea integration plugin for Neovim, built as an extension for
[snacks.nvim](https://github.com/folke/snacks.nvim). This plugin wraps the [tea
CLI](https://gitea.com/gitea/tea) to provide native PR management directly
within Neovim.

<img width="3070" height="2196" alt="ss_1769422957" src="https://github.com/user-attachments/assets/3c57db80-101c-4ca0-b817-4fa8fffcda62" />


## Features

- 📋 **List & Browse PRs** - View all pull requests with filtering
- 🔄 **Checkout PRs** - Quickly checkout PR branches locally  
- ✍️ **Review PRs** - Approve, request changes, or comment on PRs
- 📝 **Create PRs** - Create pull requests from the current branch
- 💬 **Comment** - Add comments to PRs
- 🔀 **Merge PRs** - Merge pull requests directly from Neovim
- 🎨 **Rich UI** - Beautiful rendering with syntax highlighting (mirroring snacks.gh)

## Requirements

- Neovim >= 0.9.4
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [tea CLI](https://gitea.com/gitea/tea) - Gitea/Forgejo command-line tool

### Installing tea CLI

**Via Nix:**
```bash
nix-shell -p tea
```

**Via Homebrew (macOS):**
```bash
brew install tea
```

**From source:**
```bash
go install gitea.com/gitea/tea@latest
```

## Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "folke/snacks.nvim",
  dependencies = {
    "your-username/snacks-tea.nvim"
  },
  opts = {
    tea = {
      enabled = true,
      tea = {
        cmd = "tea",  -- Path to tea binary
        login = nil,  -- Specific login to use (nil = auto-detect)
        remote = "origin",  -- Git remote to use
      },
    }
  }
}
```

## Configuration

### Tea CLI Setup

First, configure tea with your Forgejo instance:

```bash
tea login add \
  --name forgejo.example.com \
  --url https://forgejo.example.com \
  --token YOUR_ACCESS_TOKEN
```

### Neovim Configuration

Full configuration example:

```lua
require("snacks").setup({
  tea = {
    enabled = true,
    
    -- Tea CLI configuration
    tea = {
      cmd = "tea",
      login = nil,  -- Use default login, or specify one
      remote = "origin",
    },
    
    -- Buffer keymaps
    keys = {
      select   = { "<cr>", "tea_actions" , desc = "Select Action" },
      diff     = { "d"   , "tea_diff"    , desc = "View Diff" },
      checkout = { "c"   , "tea_checkout", desc = "Checkout PR" },
      approve  = { "A"   , "tea_approve" , desc = "Approve PR" },
      comment  = { "a"   , "tea_comment" , desc = "Add Comment" },
      close    = { "x"   , "tea_close"   , desc = "Close" },
      reopen   = { "o"   , "tea_reopen"  , desc = "Reopen" },
    },
    
    -- Icons (customize if desired)
    icons = {
      pr = {
        open   = " ",
        closed = " ",
        merged = " ",
        draft  = " ",
      }
    }
  }
})

### Global Keymaps

Add these to your keymap setup:

```lua
keys = {
  { "<leader>tp", function() Snacks.tea.pr() end, desc = "Tea Pull Requests (open)" },
  { "<leader>tP", function() Snacks.tea.pr { state = "all" } end, desc = "Tea Pull Requests (all)" },
  { "<leader>tc", function() Snacks.tea.pr_create {} end, desc = "Tea Create Pull Request" },
},
```

## GH-Style Visualization

The plugin now features a visual style closely matching `snacks.gh`:

- **Badges & Icons**: Colored state badges (e.g., green for open PRs), user icons, label colors from Forgejo.
- **Rich Rendering**: Highlighted metadata, indented comments with visual guides (`┃`), syntax-highlighted diffs.
- **Picker Integration**: Compact list with state icons, authors, and label badges.

This is enabled by default via `gh_style.enabled = true`. To disable for minimal rendering:

```lua
{
  tea = {
    gh_style = {
      enabled = false,  -- Plain markdown, no icons/highlights
    },
  },
}
```

Future: Toggle colors (github vs gitea palette).

## Usage

### Commands

```vim
:lua Snacks.tea.pr()              " List all open PRs
:lua Snacks.tea.pr({ state = "closed" })  " List closed PRs
```

### Picker Actions

When viewing the PR list, you can:

- `<CR>` - Show available actions
- `d` - View PR diff in separate viewer
- `c` - Checkout PR locally
- `A` - Approve PR (shift+a)
- `a` - Add comment
- `x` - Close PR
- `o` - Reopen PR
- `y` - Yank PR URL to clipboard

### PR Actions

<img width="1712" height="652" alt="ss_1769423138" src="https://github.com/user-attachments/assets/2ea24749-0168-4b19-8f34-0c1e89b0e455" />

Once viewing a PR, available actions include:

- **View Diff** (`d`) - Open a file-by-file diff viewer with navigation
- **Checkout** (`c`) - `tea pr checkout <number>`
- **Approve** (`A`) - `tea pr approve <number>`
- **Request Changes** - `tea pr reject <number>`
- **Comment** (`a`) - `tea pr comment <number>`
- **Merge** - `tea pr merge <number>`
- **Close** (`x`) - `tea pr close <number>`
- **Reopen** (`o`) - `tea pr reopen <number>`

### Diff Viewer

<img width="3118" height="2162" alt="ss_1769423306" src="https://github.com/user-attachments/assets/f8b4e72d-4a2c-448a-91e6-0156093001bf" />

The diff viewer (`d` key) provides an enhanced view of PR changes:

- 📁 **File-by-file navigation** - Browse through changed files
- 🔍 **Syntax-highlighted preview** - Full diff preview with syntax highlighting
- ⚡ **Quick actions** - Add comments or perform actions directly from diff view
- 🎯 **Jump to file** - Navigate to specific files and line numbers

The diff viewer mirrors the excellent UX of `snacks.gh` while working with Forgejo/Gitea.

## Architecture

This plugin follows the architecture of `snacks.gh` closely:

```
lua/snacks/tea/
├── init.lua          # Main module, config, setup
├── api.lua           # Tea CLI wrapper
├── actions.lua       # User actions (checkout, review, merge, etc.)
├── buf.lua           # Buffer management for PR viewing
├── item.lua          # Data model for PRs
├── types.lua         # Type definitions
└── render/
    └── init.lua      # PR markdown rendering
```

## Comparison with snacks.gh

| Feature | snacks.gh (GitHub) | snacks-tea.nvim |
|---------|-------------------|---------------------|
| CLI Tool | `gh` (official GitHub CLI) | `tea` (Gitea/Forgejo CLI) |
| List PRs | ✅ | ✅ |
| View PR | ✅ | ✅ |
| View Diff | ✅ | ✅ |
| Checkout PR | ✅ | ✅ |
| Create PR | ✅ | ✅ | |
| Review PR | ✅ | ✅ |
| Inline comments | ✅ | ✅ | |
| GraphQL support | ✅ | ❌ (tea uses REST) |
| Self-hosted | ❌ (GitHub only) | ✅ (Any Forgejo/Gitea) |

## Troubleshooting

### Tea CLI not found

Error: `Tea CLI not found: tea`

**Solution:** Install tea CLI (see Requirements above)

### No matching login

Error: `No git repository found` or authentication errors

**Solution:** Make sure you're in a git repository and that tea is configured:

```bash
tea login list
tea repos ls  # Test connection
```

### Tea not detecting repository

**Solution:** Use the `--repo` flag or ensure your git remote matches your tea login:

```bash
git remote get-url origin
```

## Roadmap

- [x] List PRs
- [x] View PR details
- [x] Checkout PRs
- [x] Review PRs (approve/reject/comment)
- [x] Merge PRs
- [x] Diff viewer integration
- [x] Create PRs from scratch buffer
- [x] Inline code comments
- [ ] PR templates support
- [ ] Multi-instance support

## Contributing

Contributions are welcome! This plugin aims to mirror the excellent UX of `snacks.gh` while supporting self-hosted Forgejo/Gitea instances.

## License

MIT

## Credits

- [folke/snacks.nvim](https://github.com/folke/snacks.nvim) - The amazing plugin framework this extends
- [tea CLI](https://gitea.com/gitea/tea) - Gitea/Forgejo command-line tool
- Inspired by the excellent `snacks.gh` GitHub integration

---

**Note:** This plugin is under active development. While core features work, some advanced features from `snacks.gh` are still being implemented.
