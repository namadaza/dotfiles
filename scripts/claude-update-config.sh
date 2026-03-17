#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$SCRIPT_DIR/../claude"

mkdir -p ~/.claude
cp -f "$CLAUDE_DIR/settings.json" ~/.claude/settings.json

# Sync skills
if [ -d "$CLAUDE_DIR/skills" ]; then
  for skill_dir in "$CLAUDE_DIR/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    mkdir -p ~/.claude/skills/"$skill_name"
    cp -f "$skill_dir"* ~/.claude/skills/"$skill_name"/
  done
fi
