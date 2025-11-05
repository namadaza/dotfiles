#!/usr/bin/env bash

# True black and gray colors
BLACK=0xff000000     # True black (for active workspace background)
WHITE=0xffffffff     # True white (for active workspace text)
GRAY_LIGHT=0xffe0e0e0  # Light gray (for inactive workspace text)

# Highlight the currently focused AeroSpace workspace
# Use environment variable from aerospace if available (faster), otherwise query directly
FOCUSED="${FOCUSED_WORKSPACE:-${AEROSPACE_FOCUSED_WORKSPACE}}"

# Only query aerospace if environment variable not available
if [ -z "$FOCUSED" ]; then
    FOCUSED=$(aerospace list-workspaces --focused)
fi

if [ "$1" = "$FOCUSED" ]; then
    sketchybar --set "$NAME" background.drawing=on label.color="$WHITE"
else
    sketchybar --set "$NAME" background.drawing=off label.color="$GRAY_LIGHT"
fi