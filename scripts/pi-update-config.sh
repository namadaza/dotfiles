#!/bin/bash

# Pi configuration update script
# Copies configuration and skills from dotfiles/pi to ~/.pi/agent

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
DOT_PI_DIR="$DOTFILES_DIR/pi"
DEST_DIR="$HOME/.pi/agent"

mkdir -p "$DEST_DIR"

# Copy settings.json
if [ -f "$DOT_PI_DIR/settings.json" ]; then
  cp -f "$DOT_PI_DIR/settings.json" "$DEST_DIR/settings.json"
  echo "✓ Copied settings.json to $DEST_DIR/settings.json"
else
  echo "✗ Warning: $DOT_PI_DIR/settings.json not found"
fi

# Sync skills
if [ -d "$DOT_PI_DIR/skills" ]; then
  for skill_dir in "$DOT_PI_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$DEST_DIR/skills/$skill_name"
    cp -rf "$skill_dir"* "$DEST_DIR/skills/$skill_name/"
    echo "✓ Synced skill: $skill_name"
  done
fi

# Copy SYSTEM.md
if [ -f "$DOT_PI_DIR/SYSTEM.md" ]; then
  cp -f "$DOT_PI_DIR/SYSTEM.md" "$DEST_DIR/SYSTEM.md"
  echo "✓ Copied SYSTEM.md to $DEST_DIR/SYSTEM.md"
fi


echo "Pi configuration update complete."
