#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -r -f "$SCRIPT_DIR/../sketchybar"/* ~/.config/sketchybar/
sketchybar --reload
