#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.claude
cp -f "$SCRIPT_DIR/../claude/settings.json" ~/.claude/settings.json
