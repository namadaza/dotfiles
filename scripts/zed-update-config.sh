#!/bin/bash

# Zed configuration update script
# Copies keymap.json from dotfiles to Zed config directory

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source and destination paths
SOURCE_KEYMAP="$DOTFILES_DIR/zed/keymap.json"
DEST_DIR="$HOME/.config/zed"
DEST_KEYMAP="$DEST_DIR/keymap.json"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy keymap.json
if [ -f "$SOURCE_KEYMAP" ]; then
    cp "$SOURCE_KEYMAP" "$DEST_KEYMAP"
    echo "✓ Copied keymap.json to $DEST_KEYMAP"
else
    echo "✗ Error: Source file not found at $SOURCE_KEYMAP"
    exit 1
fi

echo "Zed configuration updated successfully!"
