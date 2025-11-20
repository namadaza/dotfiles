#!/bin/sh

# True black and gray colors
WHITE=0xffffffff     # True white
GRAY_LIGHT=0xffe0e0e0  # Light gray

# Get today's date in DD-MM-YYYY format
TODAY=$(date +"%d-%m-%Y")

# API endpoint - using Los Angeles, CA as default
ADDRESS="Los+Angeles%2C+CA%2C+US"
API_URL="https://api.aladhan.com/v1/timingsByAddress/${TODAY}?address=${ADDRESS}&method=2&shafaq=general&school=1&timezonestring=America%2FLos_Angeles&calendarMethod=UAQ"

# Fetch prayer times data
PRAYER_DATA=$(curl -s "$API_URL" 2>/dev/null)

# Parse prayer times
if [ -z "$PRAYER_DATA" ]; then
  ICON="?"
  LABEL="--"
else
  # Extract timings using jq if available, otherwise use grep/sed
  if command -v jq >/dev/null 2>&1; then
    FAJR=$(echo "$PRAYER_DATA" | jq -r '.data.timings.Fajr // empty' 2>/dev/null)
    SUNRISE=$(echo "$PRAYER_DATA" | jq -r '.data.timings.Sunrise // empty' 2>/dev/null)
    DHUHR=$(echo "$PRAYER_DATA" | jq -r '.data.timings.Dhuhr // empty' 2>/dev/null)
    ASR=$(echo "$PRAYER_DATA" | jq -r '.data.timings.Asr // empty' 2>/dev/null)
    MAGHRIB=$(echo "$PRAYER_DATA" | jq -r '.data.timings.Maghrib // empty' 2>/dev/null)
    ISHA=$(echo "$PRAYER_DATA" | jq -r '.data.timings.Isha // empty' 2>/dev/null)
  else
    # Fallback parsing without jq
    FAJR=$(echo "$PRAYER_DATA" | grep -oE '"Fajr"\s*:\s*"[0-9]{2}:[0-9]{2}"' | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)
    SUNRISE=$(echo "$PRAYER_DATA" | grep -oE '"Sunrise"\s*:\s*"[0-9]{2}:[0-9]{2}"' | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)
    DHUHR=$(echo "$PRAYER_DATA" | grep -oE '"Dhuhr"\s*:\s*"[0-9]{2}:[0-9]{2}"' | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)
    ASR=$(echo "$PRAYER_DATA" | grep -oE '"Asr"\s*:\s*"[0-9]{2}:[0-9]{2}"' | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)
    MAGHRIB=$(echo "$PRAYER_DATA" | grep -oE '"Maghrib"\s*:\s*"[0-9]{2}:[0-9]{2}"' | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)
    ISHA=$(echo "$PRAYER_DATA" | grep -oE '"Isha"\s*:\s*"[0-9]{2}:[0-9]{2}"' | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)
  fi
  
  # Get current time in HH:MM format (24-hour)
  CURRENT_TIME=$(date +"%H:%M")
  
  # Convert time strings to minutes since midnight for comparison
  time_to_minutes() {
    echo "$1" | awk -F: '{print $1 * 60 + $2}'
  }
  
  # Convert 24-hour time (HH:MM) to 12-hour format with AM/PM
  format_time_12hr() {
    echo "$1" | awk -F: '{
      hour = $1
      min = $2
      if (hour == 0) {
        printf "12:%02dAM", min
      } else if (hour < 12) {
        printf "%d:%02dAM", hour, min
      } else if (hour == 12) {
        printf "12:%02dPM", min
      } else {
        printf "%d:%02dPM", hour - 12, min
      }
    }'
  }
  
  CURRENT_MINUTES=$(time_to_minutes "$CURRENT_TIME")
  
  # Find the next prayer time
  NEXT_PRAYER=""
  NEXT_TIME=""
  NEXT_ICON=""
  NEXT_MINUTES=9999
  
  # Check each prayer time
  # Use pipe delimiter to avoid issues with colons in time format
  for prayer_info in "FAJR|$FAJR" "SUNRISE|$SUNRISE" "DHUHR|$DHUHR" "ASR|$ASR" "MAGHRIB|$MAGHRIB" "ISHA|$ISHA"; do
    prayer_name=$(echo "$prayer_info" | cut -d'|' -f1)
    prayer_time=$(echo "$prayer_info" | cut -d'|' -f2)
    
    if [ -z "$prayer_time" ]; then
      continue
    fi
    
    prayer_minutes=$(time_to_minutes "$prayer_time")
    
    # If prayer time is today and hasn't passed, or if all prayers have passed (use tomorrow's first prayer)
    if [ "$prayer_minutes" -gt "$CURRENT_MINUTES" ]; then
      if [ "$prayer_minutes" -lt "$NEXT_MINUTES" ]; then
        NEXT_MINUTES=$prayer_minutes
        NEXT_TIME=$prayer_time
        NEXT_PRAYER=$prayer_name
      fi
    fi
  done
  
  # If no prayer found for today, fetch tomorrow's data and use tomorrow's Fajr
  if [ -z "$NEXT_PRAYER" ]; then
    TOMORROW=$(date -v+1d +"%d-%m-%Y" 2>/dev/null || date -d "+1 day" +"%d-%m-%Y" 2>/dev/null || date +"%d-%m-%Y")
    TOMORROW_API_URL="https://api.aladhan.com/v1/timingsByAddress/${TOMORROW}?address=${ADDRESS}&method=2&shafaq=general&school=1&timezonestring=America%2FLos_Angeles&calendarMethod=UAQ"
    TOMORROW_DATA=$(curl -s "$TOMORROW_API_URL" 2>/dev/null)
    
    if [ -n "$TOMORROW_DATA" ]; then
      if command -v jq >/dev/null 2>&1; then
        NEXT_TIME=$(echo "$TOMORROW_DATA" | jq -r '.data.timings.Fajr // empty' 2>/dev/null)
      else
        NEXT_TIME=$(echo "$TOMORROW_DATA" | grep -oE '"Fajr"\s*:\s*"[0-9]{2}:[0-9]{2}"' | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)
      fi
      NEXT_PRAYER="FAJR"
    else
      # Fallback to today's Fajr if tomorrow's data can't be fetched
      NEXT_PRAYER="FAJR"
      NEXT_TIME=$FAJR
    fi
  fi
  
  # Set icon based on prayer name
  # Icons provided by user: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
  case "$NEXT_PRAYER" in
    FAJR) NEXT_ICON="󰽦" ;;
    SUNRISE) NEXT_ICON="󰖜" ;;
    DHUHR) NEXT_ICON="󰖙" ;;
    ASR) NEXT_ICON="󰖛" ;;
    MAGHRIB) NEXT_ICON="󰖚" ;;
    ISHA) NEXT_ICON="󰖔" ;;
    *) NEXT_ICON="????" ;;
  esac
  
  # Format label with prayer name and time
  if [ -n "$NEXT_TIME" ]; then
    LABEL=$(format_time_12hr "$NEXT_TIME")
    ICON="$NEXT_ICON"
  else
    ICON="?"
    LABEL="--"
  fi
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$GRAY_LIGHT" label="$LABEL" label.color="$WHITE"
