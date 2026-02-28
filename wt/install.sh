#!/bin/bash

# wt install script
# Copies wt to ~/.local/bin/wt and installs zsh completions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install binary
SOURCE="$SCRIPT_DIR/wt"
DEST="$HOME/.local/bin/wt"

mkdir -p "$HOME/.local/bin"

cp "$SOURCE" "$DEST"
chmod +x "$DEST"
echo "✓ Installed wt to $DEST"

# Install zsh completion
COMP_DIR="${ZSH_COMPLETIONS_DIR:-$HOME/.local/share/zsh/site-functions}"
mkdir -p "$COMP_DIR"
cp "$SCRIPT_DIR/_wt" "$COMP_DIR/_wt"
echo "✓ Installed zsh completion to $COMP_DIR/_wt"
echo "  (ensure $COMP_DIR is in your fpath, then run: autoload -Uz compinit && compinit)"
