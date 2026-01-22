# snacks-forgejo.nvim

A Forgejo/Gitea integration plugin for Neovim, built as an extension for [snacks.nvim](https://github.com/folke/snacks.nvim). This plugin wraps the [tea CLI](https://gitea.com/gitea/tea) to provide native PR management directly within Neovim.

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
    "your-username/snacks-forgejo.nvim"
  },
  opts = {
    forgejo = {
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
  --name forgejo.pyn.ru \
  --url https://forgejo.pyn.ru \
  --token YOUR_ACCESS_TOKEN
```

### Neovim Configuration

Full configuration example:

```lua
require("snacks").setup({
  forgejo = {
    enabled = true,
    
    -- Tea CLI configuration
    tea = {
      cmd = "tea",
      login = nil,  -- Use default login, or specify one
      remote = "origin",
    },
    
    -- Buffer keymaps
    keys = {
      select   = { "<cr>", "fg_actions" , desc = "Select Action" },
      checkout = { "c"   , "fg_checkout", desc = "Checkout PR" },
      comment  = { "a"   , "fg_comment" , desc = "Add Comment" },
      close    = { "x"   , "fg_close"   , desc = "Close" },
      reopen   = { "o"   , "fg_reopen"  , desc = "Reopen" },
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
```

## Usage

### Commands

```vim
:lua Snacks.forgejo.pr()              " List all open PRs
:lua Snacks.forgejo.pr({ state = "closed" })  " List closed PRs
```

### Picker Actions

When viewing the PR list, you can:

- `<CR>` - Show available actions
- `c` - Checkout PR locally
- `o` - Open PR in web browser
- `y` - Yank PR URL to clipboard

### PR Actions

Once viewing a PR, available actions include:

- **Checkout** - `tea pr checkout <number>`
- **Approve** - `tea pr approve <number>`
- **Request Changes** - `tea pr reject <number>`
- **Comment** - `tea pr comment <number>`
- **Merge** - `tea pr merge <number>`
- **Close/Reopen** - `tea pr close/reopen <number>`

## Architecture

This plugin follows the architecture of `snacks.gh` closely:

```
lua/snacks/forgejo/
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

| Feature | snacks.gh (GitHub) | snacks-forgejo.nvim |
|---------|-------------------|---------------------|
| CLI Tool | `gh` (official GitHub CLI) | `tea` (Gitea/Forgejo CLI) |
| List PRs | ✅ | ✅ |
| View PR | ✅ | ✅ |
| Checkout PR | ✅ | ✅ |
| Create PR | ✅ | 🚧 (Planned) |
| Review PR | ✅ | ✅ |
| Inline comments | ✅ | 🚧 (Planned) |
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
- [ ] Create PRs from scratch buffer
- [ ] Inline code comments
- [ ] Diff viewer integration
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
