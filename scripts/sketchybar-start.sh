#!/bin/bash

# Start SketchyBar if it's not already running

# Check if sketchybar service is already running
if launchctl list | grep -q "homebrew.mxcl.sketchybar"; then
    echo "SketchyBar service is already running"
    exit 0
fi

# Start sketchybar via Homebrew service
echo "Starting SketchyBar service..."
brew services start sketchybar

# Wait a moment and verify it started
sleep 1
if pgrep -x "sketchybar" > /dev/null; then
    echo "SketchyBar started successfully"
else
    echo "Failed to start SketchyBar"
    exit 1
fi
