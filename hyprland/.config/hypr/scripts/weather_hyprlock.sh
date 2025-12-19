#!/bin/bash
# Hyprlock weather widget script
# Usage: weather_hyprlock.sh [icon|temp|city|condition|temp-condition|full]

CACHE_PROXY_URL="${WEATHER_CACHE_URL:-http://10.10.10.9:7722}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather"
CACHE_FILE="$CACHE_DIR/weather_data.json"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Fetch data
data=$(curl -s --max-time 3 "${CACHE_PROXY_URL}/v1/forecast" 2>/dev/null)
if [[ $? -eq 0 ]] && [[ -n "$data" ]] && [[ "$data" != *"error"* ]]; then
    echo "$data" > "$CACHE_FILE"
else
    # Use cached data if available
    if [[ -f "$CACHE_FILE" ]]; then
        data=$(cat "$CACHE_FILE")
    else
        echo "N/A"
        exit 0
    fi
fi

# Parse current weather
current_temp=$(echo "$data" | jq -r '.current_weather.temperature // "N/A"')
current_code=$(echo "$data" | jq -r '.current_weather.weathercode // 0')

# Determine city name
CITY="${WEATHER_CITY}"
if [[ -z "$CITY" ]]; then
    # Try to get custom city name from API response (set by proxy)
    api_city=$(echo "$data" | jq -r '._city // empty')
    if [[ -n "$api_city" ]]; then
        CITY="$api_city"
    else
        # Fall back to extracting city from timezone
        api_timezone=$(echo "$data" | jq -r '.timezone // empty')
        if [[ -n "$api_timezone" ]] && [[ "$api_timezone" == *"/"* ]]; then
            CITY="${api_timezone##*/}"
            # Replace underscores with spaces
            CITY="${CITY//_/ }"
        else
            CITY="Weather"
        fi
    fi
fi

# Get weather icon
get_weather_icon() {
    local code=$1
    local hour=$((10#$(date +%H)))
    local is_night=0
    
    if [[ $hour -ge 18 || $hour -lt 6 ]]; then
        is_night=1
    fi
    
    if [[ $is_night -eq 1 ]]; then
        case $code in
        0) echo "🌙" ;;
        1) echo "🌙" ;;
        2) echo "☁️" ;;
        3) echo "☁️" ;;
        45 | 48) echo "🌫️" ;;
        51 | 53 | 55 | 80) echo "🌧️" ;;
        61 | 63 | 65 | 81 | 82) echo "🌧️" ;;
        66 | 67) echo "🌧️" ;;
        71 | 73 | 75) echo "❄️" ;;
        95 | 96 | 99) echo "⛈️" ;;
        *) echo "❓" ;;
        esac
    else
        case $code in
        0) echo "☀️" ;;
        1) echo "🌤️" ;;
        2) echo "⛅" ;;
        3) echo "☁️" ;;
        45 | 48) echo "🌫️" ;;
        51 | 53 | 55 | 80) echo "🌦️" ;;
        61 | 63 | 65 | 81 | 82) echo "🌧️" ;;
        66 | 67) echo "🌧️" ;;
        71 | 73 | 75) echo "❄️" ;;
        95 | 96 | 99) echo "⛈️" ;;
        *) echo "❓" ;;
        esac
    fi
}

get_weather_desc() {
    local code=$1
    case $code in
    0) echo "Clear" ;;
    1) echo "Mainly Clear" ;;
    2) echo "Partly Cloudy" ;;
    3) echo "Overcast" ;;
    45 | 48) echo "Fog" ;;
    51 | 53 | 55) echo "Drizzle" ;;
    61) echo "Light Rain" ;;
    63) echo "Rain" ;;
    65) echo "Heavy Rain" ;;
    66 | 67) echo "Freezing Rain" ;;
    71 | 73 | 75) echo "Snow" ;;
    80) echo "Light Showers" ;;
    81) echo "Showers" ;;
    82) echo "Heavy Showers" ;;
    95 | 96 | 99) echo "Thunderstorm" ;;
    *) echo "Unknown" ;;
    esac
}

icon=$(get_weather_icon "$current_code")
desc=$(get_weather_desc "$current_code")

# Output based on argument
case "${1:-full}" in
    icon)
        echo "$icon"
        ;;
    city)
        echo "$CITY"
        ;;
    temp)
        echo "${current_temp}°C"
        ;;
    condition)
        echo "$desc"
        ;;
    temp-condition)
        echo "${current_temp}°C - $desc"
        ;;
    full)
        echo "$icon  ${current_temp}°C  $desc  •  $CITY"
        ;;
    *)
        echo "$icon  ${current_temp}°C  $desc"
        ;;
esac
