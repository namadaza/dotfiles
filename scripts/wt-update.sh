#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/../wt"
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/worktrunk"

mkdir -p "$DEST_DIR"

# Keep a backup before replacing an existing, different user configuration.
if [[ -f "$DEST_DIR/config.toml" ]] && ! cmp -s "$SOURCE_DIR/config.toml" "$DEST_DIR/config.toml"; then
  BACKUP="$(mktemp "$DEST_DIR/config.toml.backup.XXXXXX")"
  cp -p "$DEST_DIR/config.toml" "$BACKUP"
  echo "Backed up existing config to $BACKUP"
fi

cp -f "$SOURCE_DIR/copy-env-local.sh" "$DEST_DIR/copy-env-local.sh"
cp -f "$SOURCE_DIR/config.toml" "$DEST_DIR/config.toml"
echo "Updated Worktrunk configuration in $DEST_DIR"
