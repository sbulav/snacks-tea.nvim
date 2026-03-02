#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v asciinema >/dev/null 2>&1; then
  echo "Error: asciinema not found. Install with: nix shell nixpkgs#asciinema"
  exit 1
fi

if ! command -v agg >/dev/null 2>&1; then
  echo "Warning: agg not found. Only .cast will be produced."
  echo "Install agg with: nix shell nixpkgs#asciinema-agg"
fi

CAST_FILE="demo/snacks-tea-demo.cast"
GIF_FILE="demo/snacks-tea-demo.gif"

echo "Recording snacks-tea.nvim demo..."
echo "Press Ctrl+D when finished."

asciinema rec \
  --command "nvim -u demo/demo.lua" \
  --title "snacks-tea.nvim demo" \
  --overwrite \
  "$CAST_FILE"

echo "Recording saved to $CAST_FILE"

if command -v agg >/dev/null 2>&1; then
  echo "Converting cast to GIF..."
  agg \
    --font-family "JetBrains Mono" \
    --font-size 16 \
    --theme catppuccin-mocha \
    --fps 30 \
    "$CAST_FILE" \
    "$GIF_FILE"
  echo "GIF saved to $GIF_FILE"
fi
