#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WT_SRC_DIR="$SCRIPT_DIR/../wt"
BIN_DEST="$HOME/.local/bin/wt"
COMP_DEST_DIR="${ZSH_COMPLETIONS_DIR:-$HOME/.local/share/zsh/site-functions}"

mkdir -p "$(dirname "$BIN_DEST")"
cp -f "$WT_SRC_DIR/wt" "$BIN_DEST"
chmod +x "$BIN_DEST"

mkdir -p "$COMP_DEST_DIR"
cp -f "$WT_SRC_DIR/_wt" "$COMP_DEST_DIR/_wt"
