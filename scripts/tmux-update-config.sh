#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

git -C "$REPO_ROOT" submodule update --init --recursive -- tmux/plugins/tmux-resurrect

cp -f "$SCRIPT_DIR/../tmux/.tmux.conf" ~/.tmux.conf
mkdir -p ~/.tmux
cp -R -f "$SCRIPT_DIR/../tmux/." ~/.tmux/
tmux source ~/.tmux.conf
