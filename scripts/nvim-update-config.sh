#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config/nvim
cp -f "$SCRIPT_DIR/../nvim/init.lua" ~/.config/nvim/init.lua
