#!/bin/bash

# Check for required commands
for cmd in curl jq bc date; do
    if ! command -v $cmd &> /dev/null; then
        echo "{\"text\":\"N/A\",\"tooltip\":\"Missing required command: $cmd\"}"
        exit 1
    fi
done

# ---------------- CACHING
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather"
CACHE_FILE="$CACHE_DIR/weather_data.json"
CACHE_DURATION=1800

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# ---------------- COMMAND-LINE ARGUMENTS
LAT=""
LON=""
CITY=""
HEADERSIZE="12"
BODYSIZE="11"

while [[ $# -gt 0 ]]; do
  case $1 in
  --lat)
    LAT="$2"
    shift 2
    ;;
  --lon)
    LON="$2"
    shift 2
    ;;
  --city)
    CITY="$2"
    shift 2
    ;;
  *) shift ;;
  esac
done

# ---------------- AUTO-LOCATION VIA IP
get_location_by_ip() {
  local response
  response=$(curl -s --max-time 5 "https://ipinfo.io/json" 2>/dev/null)
  if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
    LAT=$(echo "$response" | jq -r '.loc' | cut -d',' -f1)
    LON=$(echo "$response" | jq -r '.loc' | cut -d',' -f2)
    CITY=$(echo "$response" | jq -r '.city // "Your Location"')
  else
    LAT="0.0"
    LON="0.0"
    CITY="Your Location"
  fi
}

# Use command-line arguments if provided, otherwise use IP-based location
if [[ -z "$LAT" ]] || [[ -z "$LON" ]]; then
  get_location_by_ip
fi
[[ -z "$CITY" ]] && CITY="Custom Location"

LOCATION_NAME="$CITY"
DAYS_FORECAST=5

URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current_weather=true&hourly=temperature_2m,apparent_temperature,weathercode,relativehumidity_2m,windspeed_10m,precipitation_probability,precipitation&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_sum&timezone=auto"

# ---------------- WEATHER ICONS
get_weather_icon() {
  local code=$1
  local time_str=$2  # Optional: ISO format time string (YYYY-MM-DDTHH:MM:SS)
  local is_night=0
  
  # Determine if it's nighttime (18:00 to 06:00)
  if [[ -n "$time_str" ]]; then
    local hour="${time_str##*T}"
    hour="${hour%%:*}"
    if [[ $hour -ge 18 || $hour -lt 6 ]]; then
      is_night=1
    fi
  else
    # Use current time if no time provided
    local current_hour=$(date +%H)
    if [[ $current_hour -ge 18 || $current_hour -lt 6 ]]; then
      is_night=1
    fi
  fi
  
  # Return night icons for clear/partly cloudy conditions
  if [[ $is_night -eq 1 ]]; then
    case $code in
    0) echo "🌙|Clear night" ;;
    1) echo "🌙|Mainly clear night" ;;
    2) echo "☁️|Partly cloudy night" ;;
    3) echo "☁️|Overcast" ;;
    45 | 48) echo "🌫️|Fog" ;;
    51 | 53 | 55) echo "🌧️|Drizzle" ;;
    61) echo "🌧️|Slight rain" ;;
    63) echo "🌧️|Moderate rain" ;;
    65) echo "🌧️|Heavy rain" ;;
    66 | 67) echo "🌧️|Freezing rain" ;;
    71 | 73 | 75) echo "❄️|Snow" ;;
    80) echo "🌧️|Slight rain showers" ;;
    81) echo "🌧️|Moderate rain showers" ;;
    82) echo "🌧️|Violent rain showers" ;;
    95 | 96 | 99) echo "⛈️|Thunderstorm" ;;
    *) echo "❓|Unknown" ;;
    esac
  else
    # Day icons
    case $code in
    0) echo "☀️|Clear sky" ;;
    1) echo "🌤️|Mainly clear" ;;
    2) echo "⛅|Partly cloudy" ;;
    3) echo "☁️|Overcast" ;;
    45 | 48) echo "🌫️|Fog" ;;
    51 | 53 | 55) echo "🌦️|Drizzle" ;;
    61) echo "🌧️|Slight rain" ;;
    63) echo "🌧️|Moderate rain" ;;
    65) echo "🌧️|Heavy rain" ;;
    66 | 67) echo "🌧️|Freezing rain" ;;
    71 | 73 | 75) echo "❄️|Snow" ;;
    80) echo "🌦️|Slight rain showers" ;;
    81) echo "🌧️|Moderate rain showers" ;;
    82) echo "🌧️|Violent rain showers" ;;
    95 | 96 | 99) echo "⛈️|Thunderstorm" ;;
    *) echo "❓|Unknown" ;;
    esac
  fi
}

get_short_desc() {
  case $1 in
  "Slight rain showers") echo "Slight rain" ;;
  "Moderate rain showers") echo "Moderate rain" ;;
  "Violent rain showers") echo "Heavy rain" ;;
  "Slight rain") echo "Slight rain" ;;
  "Moderate rain") echo "Mod rain" ;;
  "Heavy rain") echo "Heavy rain" ;;
  "Freezing rain") echo "Freezing rain" ;;
  "Snow") echo "Snow" ;;
  "Clear sky") echo "Clear" ;;
  "Clear night") echo "Clear night" ;;
  "Mainly clear") echo "Mainly clear" ;;
  "Mainly clear night") echo "Clear night" ;;
  "Partly cloudy") echo "Part cloudy" ;;
  "Partly cloudy night") echo "Part cloudy" ;;
  "Overcast") echo "Overcast" ;;
  "Fog") echo "Fog" ;;
  "Drizzle") echo "Drizzle" ;;
  "Thunderstorm") echo "Thunderstorm" ;;
  *) echo "$1" ;;
  esac
}

# ---------------- COLORS
FG_HEADER="#f4b8e4"
FG_TEXT="#ffffff"

temp_to_color() {
  local temp=$1
  if (($(echo "$temp <= 15" | bc -l))); then
    echo "#8caaee"
  elif (($(echo "$temp <= 18" | bc -l))); then
    echo "#85c1dc"
  elif (($(echo "$temp <= 21" | bc -l))); then
    echo "#99d1db"
  elif (($(echo "$temp <= 24" | bc -l))); then
    echo "#81c8be"
  elif (($(echo "$temp <= 27" | bc -l))); then
    echo "#a6d189"
  elif (($(echo "$temp <= 30" | bc -l))); then
    echo "#e5c890"
  elif (($(echo "$temp <= 32" | bc -l))); then
    echo "#ef9f76"
  elif (($(echo "$temp <= 33" | bc -l))); then
    echo "#ea999c"
  else
    echo "#e78284"
  fi
}

# ---------------- ERROR HANDLING
fail() {
  local msg="${1:-Weather unavailable}"
  echo "{\"text\":\"N/A\",\"tooltip\":\"<span foreground='$FG_HEADER'>$msg</span>\"}"
  exit 0
}

# ---------------- FETCH DATA
# Check if cache exists and is fresh
use_cache=0
if [[ -f "$CACHE_FILE" ]]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
    if [[ $cache_age -lt $CACHE_DURATION ]]; then
        use_cache=1
    fi
fi

if [[ $use_cache -eq 1 ]]; then
    # Use cached data
    data=$(cat "$CACHE_FILE")
    if [[ -z "$data" ]]; then
        # Cache file is empty or corrupted, fetch new data
        data=$(curl -s --max-time 10 "$URL" 2>/dev/null)
        if [[ $? -eq 0 ]] && [[ -n "$data" ]]; then
            echo "$data" > "$CACHE_FILE"
        else
            fail "Failed to fetch weather"
        fi
    fi
else
    # Fetch fresh data
    data=$(curl -s --max-time 10 "$URL" 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -n "$data" ]]; then
        # Save to cache
        echo "$data" > "$CACHE_FILE"
    else
        # Try to use stale cache as fallback
        if [[ -f "$CACHE_FILE" ]]; then
            data=$(cat "$CACHE_FILE")
            if [[ -z "$data" ]]; then
                fail "Failed to fetch weather"
            fi
        else
            fail "Failed to fetch weather"
        fi
    fi
fi

# ---------------- CURRENT WEATHER
current_temp=$(echo "$data" | jq -r '.current_weather.temperature // empty')
current_code=$(echo "$data" | jq -r '.current_weather.weathercode // empty')

if [[ -z "$current_temp" ]] || [[ -z "$current_code" ]]; then
  fail "Failed to parse current weather"
fi

weather_info=$(get_weather_icon "$current_code")
icon="${weather_info%%|*}"
desc="${weather_info##*|}"

# Get current time info
current_hour=$(date +%H)
current_date=$(date +%Y-%m-%d)
current_datetime=$(date +"%Y-%m-%dT%H:00:00")

times=($(echo "$data" | jq -r '.hourly.time[]'))
apparent_temps=($(echo "$data" | jq -r '.hourly.apparent_temperature[]'))
humidity_arr=($(echo "$data" | jq -r '.hourly.relativehumidity_2m[]'))
wind_arr=($(echo "$data" | jq -r '.hourly.windspeed_10m[]'))
rain_arr=($(echo "$data" | jq -r '.hourly.precipitation_probability[]'))
precip_arr=($(echo "$data" | jq -r '.hourly.precipitation[]'))
temps_h=($(echo "$data" | jq -r '.hourly.temperature_2m[]'))
codes_h=($(echo "$data" | jq -r '.hourly.weathercode[]'))

current_index=0
for i in "${!times[@]}"; do
  time_date="${times[$i]%%T*}"
  time_hour="${times[$i]##*T}"
  time_hour="${time_hour%%:*}"
  if [[ "$time_date" == "$current_date" ]] && [[ "$time_hour" == "$current_hour" ]]; then
    current_index=$i
    break
  fi
done

feels_like="${apparent_temps[$current_index]}"
humidity="${humidity_arr[$current_index]}"
windspeed="${wind_arr[$current_index]}"

temp_color=$(temp_to_color "$current_temp")
text="$icon <span foreground='$temp_color'>${current_temp}°C</span>"

# ---------------- TOOLTIP BUILDING
tooltip=""

# Current conditions
tooltip+="<span foreground='$FG_HEADER' font='$HEADERSIZE'>🌍 Current Weather - $LOCATION_NAME</span>\n"
tooltip+="<span foreground='#ffffff'>────────────────────────────────────────</span>\n"

feels_color=$(temp_to_color "$feels_like")
tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>🌡️ <span foreground='$temp_color'>${current_temp}°C</span> (Feels like <span foreground='$feels_color'>${feels_like}°C</span>)</span>\n"
tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>$icon $desc</span>\n"
tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>💧 Humidity: ${humidity}%</span>\n"
tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>🌬️ Wind Speed: ${windspeed} km/h</span>\n\n"

# Today forecast
tooltip+="<span foreground='$FG_HEADER' font='$HEADERSIZE'>☀️ Today Forecast:</span>\n"
tooltip+="<span foreground='#ffffff'>────────────────────────────────────────</span>\n"

# Rain probability today (only future hours)
max_rain_prob=0
rain_start_time=""
precip_total=0

for i in "${!times[@]}"; do
  time_date="${times[$i]%%T*}"
  
  if [[ "$time_date" == "$current_date" ]] && [[ "${times[$i]}" > "$current_datetime" ]]; then
    prob="${rain_arr[$i]}"
    precip="${precip_arr[$i]}"
    if (($(echo "$prob > $max_rain_prob" | bc -l))); then
      max_rain_prob="$prob"
    fi
    if [[ -z "$rain_start_time" ]] && (($(echo "$prob > 0" | bc -l))); then
      rain_start_time="${times[$i]##*T}"
      rain_start_time="${rain_start_time:0:5}"
    fi
    precip_total=$(echo "$precip_total + $precip" | bc -l)
  fi
done

if (($(echo "$max_rain_prob > 0" | bc -l))); then
  tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>🌧️ Chance of rain today: ${max_rain_prob}%</span>\n"
  if [[ -n "$rain_start_time" ]]; then
    tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>⏱️ Expected rain start: ${rain_start_time}</span>\n"
  fi
  precip_formatted=$(printf "%.1f" "$precip_total")
  tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>☔ Total predicted rain: ${precip_formatted} mm</span>\n"
  tooltip+="\n"
fi

# Hourly forecast for today (only future hours)
for i in "${!times[@]}"; do
  time_date="${times[$i]%%T*}"
  time_full="${times[$i]##*T}"
  time_hm="${time_full:0:5}"

  if [[ "$time_date" == "$current_date" ]] && [[ "${times[$i]}" > "$current_datetime" ]]; then
    temp_h="${temps_h[$i]}"
    code_h="${codes_h[$i]}"
    weather_info=$(get_weather_icon "$code_h" "${times[$i]}")
    icon_h="${weather_info%%|*}"
    desc_h="${weather_info##*|}"
    short_desc=$(get_short_desc "$desc_h")
    color=$(temp_to_color "$temp_h")
    tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>$time_hm - <span foreground='$color'>${temp_h}°C</span> $icon_h $short_desc</span>\n"
  fi
done
tooltip+="\n"

# Tomorrow forecast
tomorrow=$(date -d "+1 day" +%Y-%m-%d)
tooltip+="<span foreground='$FG_HEADER' font='$HEADERSIZE'>⛅ Tomorrow Forecast:</span>\n"
tooltip+="<span foreground='#ffffff'>────────────────────────────────────────</span>\n"

for i in "${!times[@]}"; do
  time_date="${times[$i]%%T*}"
  time_full="${times[$i]##*T}"
  time_hour="${time_full%%:*}"

  if [[ "$time_date" == "$tomorrow" ]]; then
    case $time_hour in
    06) label="Morning  " ;;
    12) label="Midday   " ;;
    15) label="Afternoon" ;;
    18) label="Evening  " ;;
    *) continue ;;
    esac

    temp_h="${temps_h[$i]}"
    code_h="${codes_h[$i]}"
    weather_info=$(get_weather_icon "$code_h" "${times[$i]}")
    icon_h="${weather_info%%|*}"
    desc_h="${weather_info##*|}"
    short_desc=$(get_short_desc "$desc_h")
    color=$(temp_to_color "$temp_h")
    tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>$label - <span foreground='$color'>${temp_h}°C</span> $icon_h $short_desc</span>\n"
  fi
done
tooltip+="\n"

# Daily forecast
tooltip+="<span foreground='$FG_HEADER' font='$HEADERSIZE'>📅 Upcoming ${DAYS_FORECAST}-day Forecast:</span>\n"
tooltip+="<span foreground='#ffffff'>────────────────────────────────────────</span>\n"

dates=($(echo "$data" | jq -r '.daily.time[]'))
max_temps=($(echo "$data" | jq -r '.daily.temperature_2m_max[]'))
min_temps=($(echo "$data" | jq -r '.daily.temperature_2m_min[]'))
codes_d=($(echo "$data" | jq -r '.daily.weathercode[]'))

for i in $(seq 1 $((DAYS_FORECAST < ${#dates[@]} ? DAYS_FORECAST : ${#dates[@]} - 1))); do
  day_name=$(date -d "${dates[$i]}" +%a)
  weather_info=$(get_weather_icon "${codes_d[$i]}")
  icon_f="${weather_info%%|*}"
  desc_full="${weather_info##*|}"
  short_desc=$(get_short_desc "$desc_full")
  max_color=$(temp_to_color "${max_temps[$i]}")
  min_color=$(temp_to_color "${min_temps[$i]}")
  tooltip+="<span foreground='$FG_TEXT' font='$BODYSIZE'>$day_name ⬆️<span foreground='$max_color'>${max_temps[$i]}°C</span> ⬇️<span foreground='$min_color'>${min_temps[$i]}°C</span> $icon_f $short_desc</span>\n"
done

# Debug output
if [[ -n "$DEBUG" ]]; then
    echo "========== WEATHER DEBUG ==========" >&2
    echo -e "$(echo "$tooltip" | sed 's/<[^>]*>//g; s/\\n/\n/g')" >&2
    echo "===================================" >&2
fi

# ---------------- OUTPUT
# Remove trailing newline from tooltip
tooltip="${tooltip%\\n}"
echo "{\"text\":\"$text\",\"tooltip\":\"$tooltip\",\"markup\":\"pango\"}"
