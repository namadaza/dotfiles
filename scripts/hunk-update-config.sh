#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config/hunk
cp -f "$SCRIPT_DIR/../hunk/config.toml" ~/.config/hunk/config.toml
