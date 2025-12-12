#!/bin/bash

# Waybar Weather Script
# Place this in ~/.config/waybar/scripts/weather.sh

# Configuration
LOCATION="${WEATHER_LOCATION:-auto}"
API_URL="https://wttr.in/${LOCATION}?format=j1"
CACHE_DIR="${HOME}/.cache/weather"
CACHE_FILE="${CACHE_DIR}/weather_${LOCATION}.json"
CACHE_DURATION=${WEATHER_CACHE_MINUTES:-30}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo '{"text":"❌ jq", "tooltip":"jq not installed"}'
    exit 1
fi

# Function to get weather icon
get_icon() {
    local condition="$1"
    case "$condition" in
        *"Clear"*|*"Sunny"*) echo "☀️" ;;
        *"Partly cloudy"*) echo "⛅" ;;
        *"Cloudy"*|*"Overcast"*) echo "☁️" ;;
        *"rain"*|*"drizzle"*|*"Rain"*|*"Drizzle"*) echo "🌧️" ;;
        *"thunder"*|*"Thunder"*) echo "⛈️" ;;
        *"snow"*|*"Snow"*) echo "❄️" ;;
        *"fog"*|*"Fog"*|*"Mist"*) echo "🌫️" ;;
        *"shower"*|*"Shower"*) echo "🌦️" ;;
        *"Patchy"*) echo "🌤️" ;;
        *) echo "🌡️" ;;
    esac
}

# Function to fetch weather data
fetch_weather() {
    mkdir -p "$CACHE_DIR"
    
    local use_cache=false
    
    if [ -f "$CACHE_FILE" ]; then
        local current_time=$(date +%s)
        local file_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
        local cache_age=$(( (current_time - file_time) / 60 ))
        
        if [ $cache_age -lt $CACHE_DURATION ]; then
            use_cache=true
        fi
    fi
    
    if [ "$use_cache" = true ]; then
        WEATHER_DATA=$(cat "$CACHE_FILE")
    else
        WEATHER_DATA=$(curl -s "$API_URL")
        
        if [ -z "$WEATHER_DATA" ] || [ "$WEATHER_DATA" == "null" ]; then
            if [ -f "$CACHE_FILE" ]; then
                WEATHER_DATA=$(cat "$CACHE_FILE")
            else
                echo '{"text":"❌", "tooltip":"Failed to fetch weather"}'
                exit 1
            fi
        else
            if echo "$WEATHER_DATA" | jq empty 2>/dev/null; then
                echo "$WEATHER_DATA" > "$CACHE_FILE"
            else
                if [ -f "$CACHE_FILE" ]; then
                    WEATHER_DATA=$(cat "$CACHE_FILE")
                else
                    echo '{"text":"❌", "tooltip":"Invalid API response"}'
                    exit 1
                fi
            fi
        fi
    fi
}

# Function to show detailed weather in terminal
show_detailed() {
    # Launch the main weather script in a terminal
    local weather_script="$HOME/.config/waybar/scripts/weather_display.sh"
    
    if [ -f "$weather_script" ]; then
        # Try different terminal emulators
        if command -v kitty &> /dev/null; then
            kitty --class floating -e "$weather_script" "$LOCATION"
        elif command -v alacritty &> /dev/null; then
            alacritty --class floating -e "$weather_script" "$LOCATION"
        elif command -v foot &> /dev/null; then
            foot --app-id floating "$weather_script" "$LOCATION"
        elif command -v wezterm &> /dev/null; then
            wezterm start --class floating "$weather_script" "$LOCATION"
        else
            notify-send "Weather" "No supported terminal found"
        fi
    else
        notify-send "Weather" "Detailed script not found at $weather_script"
    fi
}

# Handle click action
if [ "$1" == "--detailed" ]; then
    show_detailed
    exit 0
fi

# Fetch weather data
fetch_weather

# Parse weather data
temp=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].temp_C')
feels_like=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].FeelsLikeC')
condition=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].weatherDesc[0].value')
humidity=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].humidity')
wind_speed=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].windspeedKmph')
precip=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].precipMM')
chance_of_rain=$(echo "$WEATHER_DATA" | jq -r '.weather[0].hourly[0].chanceofrain')
location=$(echo "$WEATHER_DATA" | jq -r '.nearest_area[0].areaName[0].value')

# Get icon
icon=$(get_icon "$condition")

# Get today's forecast
max_temp=$(echo "$WEATHER_DATA" | jq -r '.weather[0].maxtempC')
min_temp=$(echo "$WEATHER_DATA" | jq -r '.weather[0].mintempC')

# Build tooltip with detailed info
tooltip="📍 ${location}\n"
tooltip+="━━━━━━━━━━━━━━━━━━━━\n"
tooltip+="🌡️  Temperature: ${temp}°C (feels ${feels_like}°C)\n"
tooltip+="☁️  Condition: ${condition}\n"
tooltip+="💧 Humidity: ${humidity}%\n"
tooltip+="🌬️  Wind: ${wind_speed} km/h\n"
tooltip+="🌧️  Precipitation: ${precip} mm\n"
tooltip+="☔ Rain Chance: ${chance_of_rain}%\n"
tooltip+="━━━━━━━━━━━━━━━━━━━━\n"
tooltip+="📊 Today: ${max_temp}°C / ${min_temp}°C\n"
tooltip+="━━━━━━━━━━━━━━━━━━━━\n"
tooltip+="Click for detailed forecast"

# Output JSON for Waybar
echo "{\"text\":\"${icon} ${temp}°C\", \"tooltip\":\"${tooltip}\", \"class\":\"weather\"}"
echo "${icon} ${temp}°C"
