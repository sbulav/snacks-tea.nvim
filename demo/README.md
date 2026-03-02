# Demo Recording Setup

This folder contains everything needed to create a deterministic demo of
`snacks-tea.nvim` without using real Forgejo/Gitea data.

## Files

| File | Purpose |
|------|---------|
| `tea-demo` | Mock `tea` CLI with static fake PR data |
| `demo.lua` | Minimal Neovim demo config |
| `record.tape` | VHS script for automated GIF recording |
| `record-asciinema.sh` | Manual recording with asciinema |

## Quick Start

```bash
# Enter reproducible environment
nix develop

# Validate the mock tea CLI
./demo/tea-demo --version
./demo/tea-demo pr ls --output json --fields index,title,state,url --state all

# Run demo config in Neovim
nvim -u demo/demo.lua

# Record GIF using VHS
vhs demo/record.tape

# Or use flake app helper
nix run .#record-demo
```

Output: `demo/snacks-tea-demo.gif`

## Recording Methods

### Option 1: VHS (automated)

```bash
nix develop
vhs demo/record.tape
```

### Option 2: Asciinema (manual)

```bash
./demo/record-asciinema.sh
```

Manual equivalent:

```bash
asciinema rec demo/snacks-tea-demo.cast --command "nvim -u demo/demo.lua"
agg --font-family "JetBrains Mono" --font-size 16 demo/snacks-tea-demo.cast demo/snacks-tea-demo.gif
```

## Demo Data Model

`demo/tea-demo` returns fake but realistic PR data for these command families:

- `tea --version`
- `tea pr ls --output json --fields ...`
- `tea issues <number> --comments`
- PR actions: `checkout`, `approve`, `reject`, `review`, `comment`, `close`, `reopen`, `merge`, `create`

No real repository, usernames, or internal links are used.

## Notes

- `demo.lua` bootstraps `lazy.nvim` and installs `folke/snacks.nvim` if missing.
- The picker is opened by `:TeaDemo` (also auto-opened at startup).
- Demo layout is explicitly sized to fit recorder windows (picker + preview + scratch).
- This bypasses repository-remote checks so demo works in any local clone.
- For deterministic actions during recording: use `Enter` to open the actions picker, then filter/select actions there.

## Troubleshooting

### Missing Nerd Font icons

Install a Nerd Font (for example JetBrainsMono Nerd Font or CaskaydiaCove Nerd Font).

### `tea-demo` not executable

```bash
chmod +x demo/tea-demo
```

### GIF too large

```bash
gifsicle -O3 --lossy=80 -k 64 demo/snacks-tea-demo.gif -o demo/snacks-tea-demo.optimized.gif
```
