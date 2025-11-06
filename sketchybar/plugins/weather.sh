#!/bin/sh

# True black and gray colors
WHITE=0xffffffff     # True white
GRAY_LIGHT=0xffe0e0e0  # Light gray

# Fetch weather condition and temperature in one request (more efficient)
# %C = weather condition text, %t = temperature
# Format: "Condition,Temperature"
WEATHER=$(curl -s 'wttr.in/burbank,%20ca?format=%C,%t')

# If curl fails or returns empty, show fallback
if [ -z "$WEATHER" ]; then
  ICON="?"
  LABEL="--"
else
  # Split the response into condition and temperature
  CONDITION=$(echo "$WEATHER" | cut -d',' -f1)
  TEMP=$(echo "$WEATHER" | cut -d',' -f2)
  # Map condition to Nerd Font weather icons
  case "$CONDITION" in
    *[Cc]lear*|*[Ss]unny*) ICON="󰖙" ;;  # nf-md-weather_sunny
    *[Cc]loud*) ICON="󰖐" ;;  # nf-md-weather_cloudy
    *[Rr]ain*|*[Dd]rizzle*) ICON="󰖗" ;;  # nf-md-weather_rainy
    *[Ss]now*) ICON="󰖘" ;;  # nf-md-weather_snowy
    *[Tt]hunder*|*[Ss]torm*) ICON="󰖓" ;;  # nf-md-weather_lightning
    *[Ff]og*|*[Mm]ist*) ICON="󰖑" ;;  # nf-md-weather_fog
    *) ICON="󰖕" ;;  # nf-md-weather_partly_cloudy (default)
  esac
  LABEL="$TEMP"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$GRAY_LIGHT" label="$LABEL" label.color="$WHITE"