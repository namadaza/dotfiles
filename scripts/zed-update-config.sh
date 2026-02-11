#!/bin/bash

# Zed configuration update script
# Copies keymap.json and settings.json from dotfiles to Zed config directory

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source and destination paths
SOURCE_DIR="$DOTFILES_DIR/zed"
DEST_DIR="$HOME/.config/zed"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy keymap.json
if [ -f "$SOURCE_DIR/keymap.json" ]; then
    cp "$SOURCE_DIR/keymap.json" "$DEST_DIR/keymap.json"
    echo "✓ Copied keymap.json to $DEST_DIR/keymap.json"
else
    echo "✗ Error: Source file not found at $SOURCE_DIR/keymap.json"
    exit 1
fi

# Copy settings.json
if [ -f "$SOURCE_DIR/settings.json" ]; then
    cp "$SOURCE_DIR/settings.json" "$DEST_DIR/settings.json"
    echo "✓ Copied settings.json to $DEST_DIR/settings.json"
else
    echo "✗ Error: Source file not found at $SOURCE_DIR/settings.json"
    exit 1
fi

echo "Zed configuration updated successfully!"
