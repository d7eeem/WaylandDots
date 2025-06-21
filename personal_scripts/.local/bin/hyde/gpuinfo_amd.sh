#!/usr/bin/env bash
# AMD GPU Info Script (Pretty JSON Output)

# Temporary file for storing query results (optional, can be omitted if not needed)
gpuQ="/tmp/hyprdots-${UID}-gpuinfo-AMD-query"

# Query AMD GPU info
amd_gpu="$(lspci -nn | grep -Ei "VGA|3D" | grep -m 1 "1002" | awk -F'Advanced Micro Devices, Inc. ' '{gsub(/ *\[[^\]]*\]/,""); gsub(/ *\([^)]*\)/,""); print $2}')"
amd_address="$(lspci | grep -Ei "VGA|3D" | grep -i "${amd_gpu}" | cut -d' ' -f1)"

# Get temperature (using sensors, may need adjustment for your system)
temperature=$(sensors | grep -m 1 -E "edge|temp1" | awk -F ':' '{print int($2)}')

# Get utilization (using radeontop if available, else fallback)
utilization=""
if command -v radeontop &> /dev/null; then
    utilization=$(radeontop -d - -l 1 | grep -m 1 'gpu' | awk '{print $2}')
    utilization=$(printf '%.1f' "$utilization")
else
    utilization="0.0"
fi

# Get current clock speed (MHz)
current_clock_speed=""
if [[ -d /sys/class/drm/card0/device ]]; then
    if [[ -f /sys/class/drm/card0/device/pp_dpm_sclk ]]; then
        current_clock_speed=$(cat /sys/class/drm/card0/device/pp_dpm_sclk | grep '*' | awk '{print $2}')
        current_clock_speed=$(echo "$current_clock_speed" | grep -o '[0-9]*')
    fi
fi
current_clock_speed=${current_clock_speed:-0}

# Get power usage (W)
power_usage=""
hwmon_path=$(ls -d /sys/class/drm/card0/device/hwmon/hwmon* 2>/dev/null | head -n1)
if [[ -n "$hwmon_path" && -f "$hwmon_path/power1_average" ]]; then
    power_usage=$(cat "$hwmon_path/power1_average")
    power_usage=$(awk -v p="$power_usage" 'BEGIN { printf("%.0f", p/1000000) }')
fi
power_usage=${power_usage:-0}

# Icon/emoji mapping for temperature
if (( temperature >= 85 )); then
    temp_icon=""; temp_emoji="🌋"
elif (( temperature >= 65 )); then
    temp_icon=""; temp_emoji="🔥"
elif (( temperature >= 45 )); then
    temp_icon=""; temp_emoji="☁️"
else
    temp_icon=""; temp_emoji="❄️"
fi

# Icon mapping for utilization
util_icon="󰾆"
if (( $(echo "$utilization >= 90" | bc -l) )); then
    util_icon=""
elif (( $(echo "$utilization >= 60" | bc -l) )); then
    util_icon="󰓅"
elif (( $(echo "$utilization >= 30" | bc -l) )); then
    util_icon="󰾅"
fi

# Power and clock icons
power_icon="󱪉"
clock_icon=""

# Compose output
text="${temp_icon} ${temperature}°C"
tooltip="${amd_gpu}\n${temp_icon} Temperature: ${temperature}°C ${temp_emoji}\n${util_icon} Utilization: ${utilization}%\n${power_icon} Power Usage: ${power_usage} W\n${clock_icon} Clock Speed: ${current_clock_speed} MHz"

json="{\"text\":\"${text}\", \"tooltip\":\"${tooltip}\"}"
echo "$json" 