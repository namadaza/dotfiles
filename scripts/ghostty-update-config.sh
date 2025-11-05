#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="/Users/amanazad/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$DEST_DIR"
cp -f "$SCRIPT_DIR/../ghostty/config" "$DEST_DIR/config"

