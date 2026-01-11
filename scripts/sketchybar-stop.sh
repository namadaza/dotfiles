#!/bin/bash

# Stop SketchyBar

# First, stop the Homebrew service if it's running
if launchctl list | grep -q "homebrew.mxcl.sketchybar"; then
    echo "Stopping SketchyBar service..."
    brew services stop sketchybar
    sleep 1
fi

# Check if sketchybar is running
if ! pgrep -x "sketchybar" > /dev/null; then
    echo "SketchyBar is not running"
    exit 0
fi

# Stop sketchybar gracefully
echo "Stopping SketchyBar process..."
sketchybar --exit

# Wait a moment and verify it stopped
sleep 1
if pgrep -x "sketchybar" > /dev/null; then
    echo "Forcefully killing SketchyBar..."
    pkill -9 "sketchybar"
    sleep 0.5
fi

# Verify it's stopped
if pgrep -x "sketchybar" > /dev/null; then
    echo "Failed to stop SketchyBar"
    exit 1
else
    echo "SketchyBar stopped successfully"
fi
