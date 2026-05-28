#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

git -C "$REPO_ROOT" submodule update --init --recursive -- tmux/plugins/tmux-resurrect

cp -f "$SCRIPT_DIR/../tmux/.tmux.conf" ~/.tmux.conf
mkdir -p ~/.tmux/plugins
cp -r -f "$SCRIPT_DIR/../tmux/plugins"/* ~/.tmux/plugins/
tmux source ~/.tmux.conf
