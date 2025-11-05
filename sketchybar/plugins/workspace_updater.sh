#!/usr/bin/env bash

# True black and gray colors
BLACK=0xff000000     # True black (for active workspace background)
WHITE=0xffffffff     # True white (for active workspace text)
GRAY_LIGHT=0xffe0e0e0  # Light gray (for inactive workspace text)

# Get focused workspace - use env var if available (faster), otherwise query
FOCUSED="${FOCUSED_WORKSPACE:-${AEROSPACE_FOCUSED_WORKSPACE}}"

# Only query aerospace if environment variable not available
if [ -z "$FOCUSED" ]; then
    FOCUSED=$(aerospace list-workspaces --focused)
fi

# Get workspaces with windows (or fallback to default set)
WORKSPACES=$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)
if [ -z "$WORKSPACES" ]; then
    WORKSPACES="1 2 3 4 5 6 11"
fi

# Get current application name from focused window
# Format: PID | App Name | Window Title
FOCUSED_WINDOW=$(aerospace list-windows --focused 2>/dev/null)
if [ -n "$FOCUSED_WINDOW" ]; then
    # Extract app name (second field, delimited by |)
    APP_NAME=$(echo "$FOCUSED_WINDOW" | cut -d'|' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
else
    APP_NAME=""
fi

# Update all workspace items and current app in a single batch command
# sketchybar will ignore --set commands for items that don't exist
sketchybar $(for sid in $WORKSPACES; do
    if [ "$sid" = "$FOCUSED" ]; then
        echo "--set space.$sid background.drawing=on label.color=$WHITE"
    else
        echo "--set space.$sid background.drawing=off label.color=$GRAY_LIGHT"
    fi
done) --set current_app label="$APP_NAME"

