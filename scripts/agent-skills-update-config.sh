#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/../agent-skills"
SKILLS_DEST="$HOME/.agents/skills"

mkdir -p "$SKILLS_DEST"

for skill_dir in "$SKILLS_SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  skill_name="$(basename "$skill_dir")"
  mkdir -p "$SKILLS_DEST/$skill_name"
  rsync -a --delete "$skill_dir" "$SKILLS_DEST/$skill_name/"
done
