#!/bin/bash

# wt install script
# Copies wt to ~/.local/bin/wt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/wt"
DEST="$HOME/.local/bin/wt"

mkdir -p "$HOME/.local/bin"

cp "$SOURCE" "$DEST"
chmod +x "$DEST"
echo "✓ Installed wt to $DEST"
