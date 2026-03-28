#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_CLAUDE_DIR="$SCRIPT_DIR/../.claude"

mkdir -p ~/.claude

# Copy settings
if [ -f "$DOT_CLAUDE_DIR/settings.json" ]; then
  cp -f "$DOT_CLAUDE_DIR/settings.json" ~/.claude/settings.json
fi

# Sync skills
if [ -d "$DOT_CLAUDE_DIR/skills" ]; then
  for skill_dir in "$DOT_CLAUDE_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    mkdir -p ~/.claude/skills/"$skill_name"
    cp -rf "$skill_dir"* ~/.claude/skills/"$skill_name"/
  done
fi
