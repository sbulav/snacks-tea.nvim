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
- 🎨 **Rich UI** - Beautiful rendering with customizable highlights and layouts
- 📐 **Configurable Layouts** - Customize picker dimensions and layouts
- 📄 **Enhanced Buffers** - Collapsible sections, toggle visibility, better readability

## Requirements

- Neovim >= 0.9.4
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [tea CLI](https://gitea.com/gitea/tea) - Gitea/Forgejo command-line tool

### Optional

- [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) - Enhanced markdown rendering in PR buffers

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
    "sbulav/snacks-tea.nvim"
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

#### Minimal Configuration

```lua
require("snacks").setup({
  tea = {
    enabled = true,
  }
})
```

#### Full Configuration Example

Here's a comprehensive example showing all available configuration options:

```lua
require("snacks").setup({
  tea = {
    enabled = true,
    
    -- Tea CLI configuration
    tea = {
      cmd = "tea",         -- Path to tea binary
      login = nil,         -- Use default login, or specify one
      remote = "origin",   -- Git remote to use
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
      refresh  = { "r"   , function(item, buf)
        if buf and buf.update then buf:update() end
      end, desc = "Refresh PR" },
    },
    
    -- UI customization
    ui = {
      -- Custom highlight groups for different elements
      highlights = {
        pr_state = {
          open = "DiagnosticOk",      -- Highlight for open PRs
          closed = "DiagnosticError",  -- Highlight for closed PRs
          merged = "DiagnosticInfo",   -- Highlight for merged PRs
          draft = "Comment",           -- Highlight for draft PRs
        },
        author = "Identifier",         -- Author badge highlight
        assignee = "Function",         -- Assignee badge highlight
        label = "Special",             -- Label badge highlight
        branch = "@markup.link",       -- Branch name highlight
        number = "Number",             -- PR number highlight
        title = "Normal",              -- PR title highlight
        comment_header = "DiagnosticInfo", -- Comment header highlight
        date = "Comment",              -- Date/time highlight
      },
      -- Scratch window dimensions for PR creation
      scratch = {
        width = 160,
        height = 20,
      },
    },
    
    -- Buffer display configuration
    buffer = {
      -- Window options for PR buffers
      wo = {
        wrap = true,
        linebreak = true,
        foldlevel = 1,      -- Start with sections collapsed
        number = false,
        signcolumn = "no",
        breakindent = true,
        showbreak = "",
        relativenumber = false,
        foldexpr = "v:lua.vim.treesitter.foldexpr()",
        foldmethod = "expr",
        concealcursor = "n",
        conceallevel = 2,
        list = false,
      },
      -- Display options
      display = {
        show_comments = true,  -- Show comment threads
        show_diff = true,      -- Show diff in buffer
        show_reviews = true,   -- Show review status
        show_checks = true,    -- Show CI checks
        fold_comments = true,  -- Auto-fold comment section
        fold_diff = true,      -- Auto-fold diff section
      },
      -- Optional integrations
      integrations = {
        render_markdown = true, -- Use render-markdown.nvim if available
      },
    },
    
    -- Layout configuration for different picker types
    layout = {
      pr_list = nil,  -- Use default layout for PR list
      actions = {
        preset = "select",  -- Use select preset for actions menu
        layout = { max_width = 60, max_height = 20 },
      },
      diff = nil,  -- Use default layout for diff viewer
      create = {
        scratch = { width = 160, height = 25 },  -- PR creation editor size
      },
    },
    
    -- Diff configuration
    diff = {
      min = 4,   -- minimum number of lines changed to show diff
      wrap = 80, -- wrap diff lines at this length
    },
    
    -- Icons (customize if desired)
    icons = {
      logo = " ",
      user = " ",
      checkmark = " ",
      crossmark = " ",
      block = "■",
      file = " ",
      checks = {
        pending = " ",
        success = " ",
        failure = "",
        skipped = " ",
      },
      pr = {
        open   = " ",
        closed = " ",
        merged = " ",
        draft  = " ",
        other  = " ",
      },
      review = {
        approved           = " ",
        changes_requested  = " ",
        commented          = " ",
        dismissed          = " ",
        pending            = " ",
      },
      merge_status = {
        clean    = " ",
        dirty    = " ",
        blocked  = " ",
        unstable = " "
      },
      reactions = {
        thumbs_up   = "👍",
        thumbs_down = "👎",
        eyes        = "👀",
        confused    = "😕",
        heart       = "❤️",
        hooray      = "🎉",
        laugh       = "😄",
        rocket      = "🚀",
      },
    },
    
    -- GH-style visualization (enabled by default)
    gh_style = {
      enabled = true,
    },
  }
})
```

### Global Keymaps

Add these to your keymap setup:

```lua
keys = {
  { "<leader>tp", function() Snacks.tea.pr() end, desc = "Tea Pull Requests (open)" },
  { "<leader>tP", function() Snacks.tea.pr { state = "all" } end, desc = "Tea Pull Requests (all)" },
  { "<leader>tc", function() Snacks.tea.pr_create {} end, desc = "Tea Create Pull Request" },
},
```

## Configuration Guide

### UI Customization

Customize highlights for different PR elements:

```lua
ui = {
  highlights = {
    -- PR state colors
    pr_state = {
      open = "DiagnosticOk",
      closed = "DiagnosticError",
      merged = "DiagnosticInfo",
      draft = "Comment",
    },
    -- Other elements
    author = "Identifier",
    assignee = "Function",
    label = "Special",
    branch = "@markup.link",
  },
}
```

### Layout Configuration

Configure layouts for different picker types:

```lua
layout = {
  -- Main PR list picker
  pr_list = {
    preset = "ivy",  -- Options: ivy, select, split, modal
    layout = {
      width = 0.9,
      height = 0.8,
    },
  },
  -- Actions menu
  actions = {
    preset = "select",
    layout = { max_width = 60, max_height = 20 },
  },
  -- Diff viewer
  diff = {
    preset = "split",
    layout = { position = "bottom", height = 0.5 },
  },
  -- PR creation editor
  create = {
    scratch = { width = 160, height = 25 },
  },
}
```

### Buffer Display Options

Control what's shown in PR buffers:

```lua
buffer = {
  display = {
    show_comments = true,   -- Show/hide comments
    show_diff = true,       -- Show/hide diff
    show_reviews = true,    -- Show/hide reviews
    show_checks = true,     -- Show/hide CI checks
    fold_comments = true,   -- Auto-fold comments section
    fold_diff = true,       -- Auto-fold diff section
  },
  integrations = {
    render_markdown = true, -- Use render-markdown.nvim if available
  },
}
```

## Usage

<img width="3270" height="1012" alt="ss_1769423937" src="https://github.com/user-attachments/assets/fa2e156a-752f-4f04-877e-770776beed8a" />

### Commands

```vim
:lua Snacks.tea.pr()                       " List all open PRs
:lua Snacks.tea.pr({ state = "closed" })   " List closed PRs
:lua Snacks.tea.pr({ state = "all" })      " List all PRs
:lua Snacks.tea.pr_create()                " Create a new PR
:TeaHealth                                 " Check Tea CLI health
```

### Buffer Commands

When viewing a PR in a buffer (`tea://...`), you can use:

- `:TeaRefresh` - Refresh the PR buffer with latest data
- `:TeaToggleComments` - Toggle comment thread visibility
- `:TeaToggleDiff` - Toggle diff section visibility

### Picker Keymaps

When viewing the PR list:

| Key | Action |
|-----|--------|
| `<CR>` | Show available actions |
| `d` | View PR diff in separate viewer |
| `c` | Checkout PR locally |
| `A` | Approve PR |
| `a` | Add comment |
| `x` | Close PR |
| `o` | Reopen PR |
| `r` | Refresh current PR |
| `y` | Yank PR URL to clipboard |
| `<a-b>` | Open PR in browser |

### PR Actions

<img width="1712" height="652" alt="ss_1769423138" src="https://github.com/user-attachments/assets/2ea24749-0168-4b19-8f34-0c1e89b0e455" />

Available actions when viewing a PR:

- **View Diff** - Open a file-by-file diff viewer with navigation
- **Checkout** - Checkout the PR branch locally
- **Approve** - Approve the PR
- **Request Changes** - Request changes on the PR
- **Comment** - Add a comment
- **Merge** - Merge the PR
- **Close** - Close the PR
- **Reopen** - Reopen a closed PR
- **Open in Browser** - Open the PR in your web browser

### Diff Viewer

<img width="3118" height="2162" alt="ss_1769423306" src="https://github.com/user-attachments/assets/f8b4e72d-4a2c-448a-91e6-0156093001bf" />

The diff viewer (`d` key) provides an enhanced view of PR changes:

- 📁 **File-by-file navigation** - Browse through changed files
- 🔍 **Syntax-highlighted preview** - Full diff preview with syntax highlighting
- ⚡ **Quick actions** - Add comments or perform actions directly from diff view
- 🎯 **Jump to file** - Navigate to specific files and line numbers

## Enhanced Features

### 🎨 UI Customization

Fully customize the visual appearance with highlight groups:

- **PR State Colors**: Different colors for open, closed, merged, and draft PRs
- **Element Highlights**: Custom colors for authors, assignees, labels, branches, numbers, titles
- **Comment Highlights**: Custom colors for comment headers and dates
- **Consistent Theming**: All UI elements respect your configured highlights

**Example**: Create a custom color scheme

```lua
ui = {
  highlights = {
    pr_state = {
      open = "@string",
      closed = "@comment",
      merged = "@function",
      draft = "@variable",
    },
    author = "@constant",
    label = "@type",
  },
}
```

### 📐 Layout Configuration

Configure picker layouts for different views with full flexibility:

- **PR List**: Customize the main PR picker layout (preset, dimensions, position)
- **Actions Menu**: Configure the actions picker with select preset
- **Diff Viewer**: Adjust the diff viewer layout (split, position, height)
- **PR Creation**: Set editor dimensions for creating PRs

**Supported presets**: `ivy`, `select`, `split`, `modal`, and more from snacks.nvim

**Example**: Use split layout for diff viewer

```lua
layout = {
  diff = {
    preset = "split",
    layout = { position = "bottom", height = 0.5 },
  },
}
```

### 📄 Enhanced Buffer Experience

Improved PR buffer viewing with advanced features:

- **Collapsible Sections**: Comments and diffs can be folded by default using vim fold markers
- **Conditional Rendering**: Show/hide comments, diffs, reviews, checks independently
- **Buffer Commands**: `:TeaRefresh`, `:TeaToggleComments`, `:TeaToggleDiff` for quick control
- **Integration Support**: Optional render-markdown.nvim integration for beautiful markdown rendering
- **Better Readability**: Fold markers (`{{{` / `}}}`), visual hierarchy, improved spacing
- **Syntax Highlighting**: Code blocks in comments and diffs are syntax highlighted

**Example**: Minimal buffer view

```lua
buffer = {
  display = {
    show_comments = false,
    show_diff = false,
    fold_comments = false,
    fold_diff = false,
  },
}
```

### GH-Style Visualization

The plugin features a visual style closely matching `snacks.gh`:

- **Badges & Icons**: Colored state badges, user icons, label colors from Forgejo
- **Rich Rendering**: Highlighted metadata, indented comments with visual guides (`┃`), syntax-highlighted diffs
- **Picker Integration**: Compact list with state icons, authors, assignee badges, and label badges

This is enabled by default. To disable for minimal rendering:

```lua
gh_style = {
  enabled = false,  -- Plain markdown, no icons/highlights
}
```

## Architecture

This plugin follows the architecture of `snacks.gh` closely:

```
lua/snacks/tea/
├── init.lua          # Main module, config, setup
├── api.lua           # Tea CLI wrapper
├── actions.lua       # User actions (checkout, review, merge, etc.)
├── buf.lua           # Buffer management for PR viewing
├── item.lua          # Data model for PRs
├── git.lua           # Git utilities
├── types.lua         # Type definitions
└── render/
    └── init.lua      # PR markdown rendering

lua/snacks/picker/
├── source/
│   └── tea.lua       # Picker sources and finders
└── config/
    └── tea.lua       # Picker configurations
```

## Comparison with snacks.gh

| Feature | snacks.gh (GitHub) | snacks-tea.nvim |
|---------|-------------------|---------------------|
| CLI Tool | `gh` (official GitHub CLI) | `tea` (Gitea/Forgejo CLI) |
| List PRs | ✅ | ✅ |
| View PR | ✅ | ✅ |
| View Diff | ✅ | ✅ |
| Checkout PR | ✅ | ✅ |
| Create PR | ✅ | ✅ |
| Review PR | ✅ | ✅ |
| Inline comments | ✅ | ✅ |
| UI Customization | ✅ | ✅ |
| Layout Config | ✅ | ✅ |
| Buffer Commands | ✅ | ✅ |
| GraphQL support | ✅ | ❌ (tea uses REST) |
| Self-hosted | ❌ (GitHub only) | ✅ (Any Forgejo/Gitea) |

## Troubleshooting

### Tea CLI not found

Error: `Tea CLI not found: tea`

**Solution:** Install tea CLI (see [Requirements](#requirements) above)

Test if tea is available:
```bash
tea --version
```

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

### Buffer not updating

If a PR buffer is not refreshing, try:

1. Use `:TeaRefresh` command
2. Close and reopen the buffer
3. Check `:TeaHealth` for issues

### Highlights not applying

If custom highlights aren't showing:

1. Ensure your colorscheme defines the highlight groups you're referencing
2. Try using basic highlight groups like `Normal`, `Comment`, `Function`
3. Check `:highlight` to see available groups

## Roadmap

- [x] List PRs
- [x] View PR details
- [x] Checkout PRs
- [x] Review PRs (approve/reject/comment)
- [x] Merge PRs
- [x] Diff viewer integration
- [x] Create PRs from scratch buffer
- [x] Inline code comments
- [x] UI customization with highlights
- [x] Layout configuration
- [x] Enhanced buffer experience
- [x] Collapsible sections
- [ ] PR templates support
- [ ] Multi-instance support
- [ ] Draft PR support
- [ ] PR labels management

## Contributing

Contributions are welcome! This plugin aims to mirror the excellent UX of `snacks.gh` while supporting self-hosted Forgejo/Gitea instances.

Please ensure:
- Code follows existing patterns
- New features are documented
- Changes are backward compatible where possible

## License

MIT

## Credits

- [folke/snacks.nvim](https://github.com/folke/snacks.nvim) - The amazing plugin framework this extends
- [tea CLI](https://gitea.com/gitea/tea) - Gitea/Forgejo command-line tool
- Inspired by the excellent `snacks.gh` GitHub integration

---

**Note:** This plugin is actively maintained and ready for production use. All core features are stable and well-tested.
