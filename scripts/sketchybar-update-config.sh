#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -r -f -p "$SCRIPT_DIR/../sketchybar"/* ~/.config/sketchybar/
# Ensure all plugin scripts are executable
chmod +x ~/.config/sketchybar/plugins/*.sh
sketchybar --reload
