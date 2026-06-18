#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_SRC="$SCRIPT_DIR/../nvim"
NVIM_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

mkdir -p "$NVIM_DEST"
rsync -a --exclude ".git/" "$NVIM_SRC"/ "$NVIM_DEST"/
