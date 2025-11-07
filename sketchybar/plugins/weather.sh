#!/bin/sh

# True black and gray colors
WHITE=0xffffffff     # True white
GRAY_LIGHT=0xffe0e0e0  # Light gray

# Get current location from IP geolocation
LOCATION_DATA=$(curl -s 'https://ipapi.co/json/' 2>/dev/null)
if [ -z "$LOCATION_DATA" ]; then
  # Fallback to ip-api.com if ipapi.co fails
  LOCATION_DATA=$(curl -s 'http://ip-api.com/json/' 2>/dev/null)
fi

# Extract latitude and longitude
# Try jq first (most reliable), then fallback to grep/sed
if command -v jq >/dev/null 2>&1; then
  LAT=$(echo "$LOCATION_DATA" | jq -r '.latitude // .lat // empty' 2>/dev/null)
  LON=$(echo "$LOCATION_DATA" | jq -r '.longitude // .lon // empty' 2>/dev/null)
else
  # Fallback parsing without jq
  LAT=$(echo "$LOCATION_DATA" | grep -o '"latitude"[[:space:]]*:[[:space:]]*[0-9.-]*' | grep -o '[0-9.-]*$' | head -1)
  if [ -z "$LAT" ]; then
    LAT=$(echo "$LOCATION_DATA" | grep -o '"lat"[[:space:]]*:[[:space:]]*[0-9.-]*' | grep -o '[0-9.-]*$' | head -1)
  fi
  LON=$(echo "$LOCATION_DATA" | grep -o '"longitude"[[:space:]]*:[[:space:]]*[0-9.-]*' | grep -o '[0-9.-]*$' | head -1)
  if [ -z "$LON" ]; then
    LON=$(echo "$LOCATION_DATA" | grep -o '"lon"[[:space:]]*:[[:space:]]*[0-9.-]*' | grep -o '[0-9.-]*$' | head -1)
  fi
fi

# Fallback coordinates if location detection fails (Burbank, CA)
if [ -z "$LAT" ] || [ -z "$LON" ]; then
  LAT="34.1808"
  LON="-118.3090"
fi

# Fetch weather data from Open Meteo API
# Include weathercode for condition, temperature_2m for current temp
# Request temperature in Fahrenheit
WEATHER_DATA=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weather_code&temperature_unit=fahrenheit&timezone=auto" 2>/dev/null)

# Parse weather data
if [ -z "$WEATHER_DATA" ]; then
  ICON="?"
  LABEL="--"
else
  # Extract temperature and weather code
  if command -v jq >/dev/null 2>&1; then
    TEMP=$(echo "$WEATHER_DATA" | jq -r '.current.temperature_2m // empty' 2>/dev/null)
    WEATHER_CODE=$(echo "$WEATHER_DATA" | jq -r '.current.weather_code // empty' 2>/dev/null)
  else
    # Fallback parsing without jq
    # Extract the "current" object section first, then parse values from it
    CURRENT_SECTION=$(echo "$WEATHER_DATA" | sed -n 's/.*"current":{\([^}]*\)}.*/\1/p')
    if [ -n "$CURRENT_SECTION" ]; then
      TEMP=$(echo "$CURRENT_SECTION" | grep -oE '"temperature_2m"\s*:\s*[-]?[0-9]+\.?[0-9]*' | grep -oE '[-]?[0-9]+\.?[0-9]*$' | head -1)
      WEATHER_CODE=$(echo "$CURRENT_SECTION" | grep -oE '"weather_code"\s*:\s*[0-9]+' | grep -oE '[0-9]+$' | head -1)
    fi
    
    # If section extraction fails, try direct search as fallback
    if [ -z "$TEMP" ]; then
      TEMP=$(echo "$WEATHER_DATA" | grep -oE '"temperature_2m"\s*:\s*[-]?[0-9]+\.?[0-9]*' | grep -oE '[-]?[0-9]+\.?[0-9]*$' | head -1)
    fi
    if [ -z "$WEATHER_CODE" ]; then
      WEATHER_CODE=$(echo "$WEATHER_DATA" | grep -oE '"weather_code"\s*:\s*[0-9]+' | grep -oE '[0-9]+$' | head -1)
    fi
  fi
  
  # Format temperature (round to nearest integer, add °F)
  if [ -n "$TEMP" ]; then
    TEMP_INT=$(echo "$TEMP" | awk '{printf "%.0f", $1}')
    LABEL="${TEMP_INT}°F"
  else
    LABEL="--"
  fi
  
  # Map WMO weather code to Nerd Font weather icons
  # WMO Weather interpretation codes (WW):
  # 0: Clear sky
  # 1-3: Mainly clear, partly cloudy, overcast
  # 45-48: Fog and depositing rime fog
  # 51-67: Drizzle and rain
  # 71-77: Snow fall
  # 80-99: Rain showers and thunderstorms
  case "$WEATHER_CODE" in
    0) ICON="󰖙" ;;  # Clear sky
    1|2|3) ICON="󰖕" ;;  # Mainly clear, partly cloudy, overcast
    45|48) ICON="󰖑" ;;  # Fog
    51|53|55|56|57|61|63|65|66|67|80|81|82) ICON="󰖗" ;;  # Drizzle/Rain
    71|73|75|77|85|86) ICON="󰖘" ;;  # Snow
    95|96|99) ICON="󰖓" ;;  # Thunderstorm
    *) ICON="󰖕" ;;  # Default: partly cloudy
  esac
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$GRAY_LIGHT" label="$LABEL" label.color="$WHITE"