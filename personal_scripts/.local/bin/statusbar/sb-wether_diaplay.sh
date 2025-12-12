#!/bin/bash

# Colors
RESET="\e[0m"
BOLD="\e[1m"
CYAN="\e[36m"
YELLOW="\e[33m"
BLUE="\e[34m"
WHITE="\e[97m"
GRAY="\e[90m"
RED="\e[31m"
GREEN="\e[32m"
ORANGE="\e[38;5;208m"
LIGHT_BLUE="\e[38;5;117m"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${RESET}"
    echo -e "${YELLOW}Please install jq: sudo apt install jq (Ubuntu/Debian) or brew install jq (Mac)${RESET}"
    exit 1
fi

# Configuration
LOCATION="${1:-auto}"  # Use first argument or auto-detect location
API_URL="https://wttr.in/${LOCATION}?format=j1"
CACHE_DIR="${HOME}/.cache/weather"
CACHE_FILE="${CACHE_DIR}/weather_${LOCATION}.json"
CACHE_DURATION=${WEATHER_CACHE_MINUTES:-30}  # Default 30 minutes, can be overridden with env var

# Global variables for day's high and low
DAY_HIGH=0
DAY_LOW=0

# Function to get color based on temperature position
get_temp_color() {
    local temp=$1
    local high=$2
    local low=$3
    
    # Calculate the range
    local range=$((high - low))
    
    # Avoid division by zero
    if [ $range -eq 0 ]; then
        echo "${GREEN}"
        return
    fi
    
    # Calculate percentage (0-100)
    local position=$(echo "scale=2; (($temp - $low) * 100) / $range" | bc)
    local pos_int=$(printf "%.0f" "$position")
    
    # Color based on position
    if [ $pos_int -ge 80 ]; then
        echo "${RED}"           # Hot (80-100%)
    elif [ $pos_int -ge 60 ]; then
        echo "${ORANGE}"        # Warm (60-80%)
    elif [ $pos_int -ge 40 ]; then
        echo "${GREEN}"         # Moderate (40-60%)
    elif [ $pos_int -ge 20 ]; then
        echo "${LIGHT_BLUE}"    # Cool (20-40%)
    else
        echo "${BLUE}"          # Cold (0-20%)
    fi
}

# Function to get weather icon
get_icon() {
    local condition="$1"
    case "$condition" in
        *"Clear"*|*"Sunny"*) echo "☀️ " ;;
        *"Partly cloudy"*) echo "⛅" ;;
        *"Cloudy"*|*"Overcast"*) echo "☁️ " ;;
        *"rain"*|*"drizzle"*|*"Rain"*|*"Drizzle"*) echo "🌧️ " ;;
        *"thunder"*|*"Thunder"*) echo "⛈️ " ;;
        *"snow"*|*"Snow"*) echo "❄️ " ;;
        *"fog"*|*"Fog"*|*"Mist"*) echo "🌫️ " ;;
        *"shower"*|*"Shower"*) echo "🌦️ " ;;
        *"Patchy"*) echo "🌤️ " ;;
        *) echo "🌡️ " ;;
    esac
}

# Function to get day name
get_day_name() {
    local offset=$1
    date -d "+${offset} days" "+%a" 2>/dev/null || date -v+${offset}d "+%a" 2>/dev/null
}

# Function to fetch weather data
fetch_weather() {
    # Create cache directory if it doesn't exist
    mkdir -p "$CACHE_DIR"
    
    local use_cache=false
    local cache_age=0
    
    # Check if cache exists and is recent
    if [ -f "$CACHE_FILE" ]; then
        local current_time=$(date +%s)
        local file_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
        cache_age=$(( (current_time - file_time) / 60 ))
        
        if [ $cache_age -lt $CACHE_DURATION ]; then
            use_cache=true
            echo -e "${GREEN}Using cached weather data (${cache_age} minutes old)${RESET}" >&2
        else
            echo -e "${YELLOW}Cache expired (${cache_age} minutes old), fetching fresh data...${RESET}" >&2
        fi
    else
        echo -e "${YELLOW}No cache found, fetching weather data for ${LOCATION}...${RESET}" >&2
    fi
    
    if [ "$use_cache" = true ]; then
        # Load from cache
        WEATHER_DATA=$(cat "$CACHE_FILE")
    else
        # Fetch fresh data
        WEATHER_DATA=$(curl -s "$API_URL")
        
        if [ -z "$WEATHER_DATA" ] || [ "$WEATHER_DATA" == "null" ]; then
            echo -e "${RED}Error: Unable to fetch weather data${RESET}" >&2
            
            # Try to use old cache if available
            if [ -f "$CACHE_FILE" ]; then
                echo -e "${YELLOW}Using stale cache as fallback...${RESET}" >&2
                WEATHER_DATA=$(cat "$CACHE_FILE")
            else
                exit 1
            fi
        else
            # Check if response is valid JSON
            if echo "$WEATHER_DATA" | jq empty 2>/dev/null; then
                # Save to cache
                echo "$WEATHER_DATA" > "$CACHE_FILE"
                echo -e "${GREEN}Weather data cached successfully${RESET}" >&2
            else
                echo -e "${RED}Error: Invalid JSON response from API${RESET}" >&2
                
                # Try to use old cache if available
                if [ -f "$CACHE_FILE" ]; then
                    echo -e "${YELLOW}Using stale cache as fallback...${RESET}" >&2
                    WEATHER_DATA=$(cat "$CACHE_FILE")
                else
                    exit 1
                fi
            fi
        fi
    fi
    
    # Get today's high and low
    DAY_HIGH=$(echo "$WEATHER_DATA" | jq -r '.weather[0].maxtempC')
    DAY_LOW=$(echo "$WEATHER_DATA" | jq -r '.weather[0].mintempC')
}

# Function to print current conditions
print_current() {
    local area=$(echo "$WEATHER_DATA" | jq -r '.nearest_area[0].areaName[0].value')
    local region=$(echo "$WEATHER_DATA" | jq -r '.nearest_area[0].region[0].value')
    local country=$(echo "$WEATHER_DATA" | jq -r '.nearest_area[0].country[0].value')
    local temp_c=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].temp_C')
    local feels_like=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].FeelsLikeC')
    local humidity=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].humidity')
    local wind_speed=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].windspeedKmph')
    local condition=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].weatherDesc[0].value')
    local precip=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].precipMM')
    local chance_of_rain=$(echo "$WEATHER_DATA" | jq -r '.weather[0].hourly[0].chanceofrain')
    local icon=$(get_icon "$condition")
    
    local temp_color=$(get_temp_color "$temp_c" "$DAY_HIGH" "$DAY_LOW")
    local feels_color=$(get_temp_color "$feels_like" "$DAY_HIGH" "$DAY_LOW")
    
    echo -e "\n${BOLD}${WHITE}Current Conditions for ${area}, ${region}, ${country}${RESET}"
    echo -e "${GRAY}════════════════════════════════════════════${RESET}"
    echo -e " ${icon} ${temp_color}${temp_c}°C${RESET} (Feels like ${feels_color}${feels_like}°C${RESET}) ${BOLD}${condition}${RESET}"
    echo -e " 💧  ${CYAN}Humidity: ${humidity}%${RESET}"
    echo -e " 🌬️  ${BLUE}Wind Speed: ${wind_speed} km/h${RESET}"
    echo -e " 🌧️  ${WHITE}Precipitation: ${precip} mm${RESET}"
    echo -e " ☔  ${YELLOW}Chance of Rain: ${chance_of_rain}%${RESET}"
}

# Function to print hourly forecast
print_hourly() {
    echo -e "\n${BOLD}${WHITE}Today Forecast (Hourly):${RESET}"
    echo -e "${GRAY}────────────────────────────────────────────${RESET}"
    
    local current_hour=$(date "+%H")
    local count=0
    
    # Get today's hourly data
    local hourly_data=$(echo "$WEATHER_DATA" | jq -r '.weather[0].hourly[] | "\(.time)|\(.tempC)|\(.weatherDesc[0].value)"')
    
    while IFS='|' read -r time temp_c condition; do
        if [ $count -ge 12 ]; then
            break
        fi
        
        # Convert time (0, 300, 600, 900, etc.) to HH:00 format
        local hour=$(printf "%02d:00" $((time / 100)))
        local icon=$(get_icon "$condition")
        local temp_color=$(get_temp_color "$temp_c" "$DAY_HIGH" "$DAY_LOW")
        
        echo -e "${hour}  ${icon} ${temp_color}${temp_c}°C${RESET} ${condition}"
        count=$((count + 1))
    done <<< "$hourly_data"
}

# Function to print tomorrow's forecast
print_tomorrow() {
    echo -e "\n${BOLD}${WHITE}Tomorrow Forecast:${RESET}"
    echo -e "${GRAY}────────────────────────────────────────────${RESET}"
    
    # Get tomorrow's data (index 1)
    local max_temp=$(echo "$WEATHER_DATA" | jq -r '.weather[1].maxtempC')
    local min_temp=$(echo "$WEATHER_DATA" | jq -r '.weather[1].mintempC')
    
    # Get hourly breakdown for tomorrow
    local morning=$(echo "$WEATHER_DATA" | jq -r '.weather[1].hourly[2] | "\(.tempC)|\(.weatherDesc[0].value)"')
    local midday=$(echo "$WEATHER_DATA" | jq -r '.weather[1].hourly[4] | "\(.tempC)|\(.weatherDesc[0].value)"')
    local afternoon=$(echo "$WEATHER_DATA" | jq -r '.weather[1].hourly[5] | "\(.tempC)|\(.weatherDesc[0].value)"')
    local evening=$(echo "$WEATHER_DATA" | jq -r '.weather[1].hourly[6] | "\(.tempC)|\(.weatherDesc[0].value)"')
    
    IFS='|' read -r temp cond <<< "$morning"
    local icon=$(get_icon "$cond")
    local temp_color=$(get_temp_color "$temp" "$max_temp" "$min_temp")
    echo -e "Morning    ${icon} ${temp_color}${temp}°C${RESET} ${cond}"
    
    IFS='|' read -r temp cond <<< "$midday"
    icon=$(get_icon "$cond")
    temp_color=$(get_temp_color "$temp" "$max_temp" "$min_temp")
    echo -e "Midday     ${icon} ${temp_color}${temp}°C${RESET} ${cond}"
    
    IFS='|' read -r temp cond <<< "$afternoon"
    icon=$(get_icon "$cond")
    temp_color=$(get_temp_color "$temp" "$max_temp" "$min_temp")
    echo -e "Afternoon  ${icon} ${temp_color}${temp}°C${RESET} ${cond}"
    
    IFS='|' read -r temp cond <<< "$evening"
    icon=$(get_icon "$cond")
    temp_color=$(get_temp_color "$temp" "$max_temp" "$min_temp")
    echo -e "Evening    ${icon} ${temp_color}${temp}°C${RESET} ${cond}"
}

# Function to print 3-day forecast
print_3day() {
    echo -e "\n${BOLD}${WHITE}Upcoming 3-day Forecast:${RESET}"
    echo -e "${GRAY}────────────────────────────────────────────${RESET}"
    
    # Get forecast for next 3 days
    for i in {0..2}; do
        local day=$(get_day_name $i)
        local max_temp=$(echo "$WEATHER_DATA" | jq -r ".weather[$i].maxtempC")
        local min_temp=$(echo "$WEATHER_DATA" | jq -r ".weather[$i].mintempC")
        local condition=$(echo "$WEATHER_DATA" | jq -r ".weather[$i].hourly[4].weatherDesc[0].value")
        local icon=$(get_icon "$condition")
        
        # Color code based on each day's own high/low
        local max_color=$(get_temp_color "$max_temp" "$max_temp" "$min_temp")
        local min_color=$(get_temp_color "$min_temp" "$max_temp" "$min_temp")
        
        printf "%-4s 🌡️  ${max_color}%-6s${RESET} 🌡️  ${min_color}%-6s${RESET} ${icon} %s\n" "$day" "${max_temp}°C" "${min_temp}°C" "$condition"
    done
}

# Main execution
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [location]"
    echo ""
    echo "Examples:"
    echo "  $0                    # Auto-detect location"
    echo "  $0 London             # Specific city"
    echo "  $0 'New York'         # City with spaces"
    echo "  $0 Riyadh             # Another city"
    echo ""
    echo "Cache Configuration:"
    echo "  Default cache duration: ${CACHE_DURATION} minutes"
    echo "  To change cache duration, set WEATHER_CACHE_MINUTES environment variable:"
    echo "  export WEATHER_CACHE_MINUTES=60  # Cache for 1 hour"
    echo "  export WEATHER_CACHE_MINUTES=15  # Cache for 15 minutes"
    echo ""
    echo "Cache Management:"
    echo "  Cache location: ${CACHE_DIR}"
    echo "  To force refresh: rm -rf ${CACHE_DIR}"
    exit 0
fi

clear
fetch_weather
print_current
print_hourly
print_tomorrow
print_3day
