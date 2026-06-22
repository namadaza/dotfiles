#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_SRC="$SCRIPT_DIR/../ohmyzsh"
ZSH_DEST="$HOME/.oh-my-zsh"

mkdir -p "$ZSH_DEST"
rsync -a --exclude ".git/" "$ZSH_SRC"/ "$ZSH_DEST"/



