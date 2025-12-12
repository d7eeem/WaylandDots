#!/bin/bash
# SYS-MON MODULE
# Snapshot: 19
# Version: 1.80
# Status: Stable

# ---------------------------------------------------
# CONFIG / ICONS / COLORS
# ---------------------------------------------------
CPU_ICON_GENERAL=""
GPU_ICON=""
MEM_ICON=""
SSD_ICON=""
HDD_ICON="󰋊"

# ---------------------------------------------------
# CPU INFO
# ---------------------------------------------------
cpu_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
max_cpu_temp=0
cpu_name="AMD Ryzen 9 9900X"
current_freq=0
max_freq=0

# Try to get CPU temperature
if [ -f "/sys/class/hwmon/hwmon0/temp1_input" ]; then
    temp_milli=$(cat /sys/class/hwmon/hwmon0/temp1_input 2>/dev/null)
    max_cpu_temp=$((temp_milli / 1000))
elif [ -f "/sys/class/hwmon/hwmon1/temp1_input" ]; then
    temp_milli=$(cat /sys/class/hwmon/hwmon1/temp1_input 2>/dev/null)
    max_cpu_temp=$((temp_milli / 1000))
fi

# Try to get CPU frequency
if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq" ]; then
    current_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    current_freq=$((current_freq / 1000))  # Convert to MHz
    max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo "0")
    max_freq=$((max_freq / 1000))
fi

# ---------------------------------------------------
# CPU POWER ESTIMATE
# ---------------------------------------------------
cpu_power=0.0
CPU_TDP_W=105

# Calculate frequency ratio
freq_ratio=1.0
if [ "$max_freq" -gt 0 ]; then
    freq_ratio=$(echo "scale=2; $current_freq / $max_freq" | bc)
fi

# Estimate power
raw_power=$(echo "scale=2; $CPU_TDP_W * $freq_ratio" | bc)
cpu_power=$(echo "scale=2; $raw_power * 0.7" | bc)

# ---------------------------------------------------
# GPU INFO FOR AMD
# ---------------------------------------------------
gpu_percent=0
gpu_temp=0
gpu_power=0.0
gpu_name="AMD GPU"
gpu_freq_current=0
gpu_freq_max=2500

# Try ROCm SMI
if command -v rocm-smi &> /dev/null; then
    output=$(rocm-smi --showuse --showtemp --showpower --showclocks 2>/dev/null)
    
    # Extract GPU usage
    if echo "$output" | grep -q "GPU use"; then
        gpu_percent=$(echo "$output" | grep "GPU use" | grep -o '[0-9]*' | head -1)
    fi
    
    # Extract temperature
    if echo "$output" | grep -q "Temperature"; then
        gpu_temp=$(echo "$output" | grep "Temperature" | grep -o '[0-9]*' | head -1)
    fi
    
    # Extract power
    if echo "$output" | grep -q "Average Graphics Package Power"; then
        gpu_power=$(echo "$output" | grep "Average Graphics Package Power" | grep -o '[0-9]*\.[0-9]*' | head -1)
    fi
fi

# ---------------------------------------------------
# MEMORY INFO
# ---------------------------------------------------
mem_total=$(free -b | grep Mem: | awk '{print $2}')
mem_used=$(free -b | grep Mem: | awk '{print $3}')
mem_used_gb=$(echo "scale=1; $mem_used / 1073741824" | bc)
mem_total_gb=$(echo "scale=1; $mem_total / 1073741824" | bc)
mem_percent=$(echo "scale=0; $mem_used * 100 / $mem_total" | bc)

# ---------------------------------------------------
# STORAGE INFO
# ---------------------------------------------------
EXCLUDE_MOUNTS="pkg\|log\|home\|boot"
partitions=$(df -h | grep -E "^/dev/" | grep -v -E "$EXCLUDE_MOUNTS" | awk '{print $6 ":" $2 ":" $5}')

CUSTOM_DRIVE_NAMES=(
    "1 TB - Omarchy  SSD"
    "1 TB - CachyOS  SSD"
    "1 TB - Windows  SSD"
    "2 TB - Games    SSD"
    "2 TB - Media    HDD"
)

storage_entries=()
idx=0
while IFS=':' read -r mountpoint size percent; do
    if [ -z "$mountpoint" ]; then
        continue
    fi
    
    temp="N/A"
    # Try to get drive temperature
    if [ -f "/sys/class/hwmon/hwmon$idx/temp1_input" ]; then
        temp_milli=$(cat "/sys/class/hwmon/hwmon$idx/temp1_input" 2>/dev/null)
        temp=$((temp_milli / 1000))
    fi
    
    percent_clean=$(echo "$percent" | tr -d '%')
    
    label_full="${CUSTOM_DRIVE_NAMES[$idx]}"
    if [ -z "$label_full" ]; then
        label_full=$(basename "$mountpoint")
    fi
    
    if [[ "$label_full" == *"Media"* ]]; then
        drive_icon="$HDD_ICON"
    else
        drive_icon="$SSD_ICON"
    fi
    
    storage_entries+=("$drive_icon:$label_full:$temp:$percent_clean")
    ((idx++))
done <<< "$partitions"

# ---------------------------------------------------
# BAR TEXT (Simplified - no Pango markup)
# ---------------------------------------------------
text="| $CPU_ICON_GENERAL ${max_cpu_temp}°C  $GPU_ICON ${gpu_temp}°C  $MEM_ICON ${mem_percent}%  $SSD_ICON ${mem_percent}% |"

# ---------------------------------------------------
# TOOLTIP BUILDING (Plain text)
# ---------------------------------------------------
tooltip_lines=()

# CPU Section
tooltip_lines+=("")
tooltip_lines+=("$CPU_ICON_GENERAL CPU:")
tooltip_lines+=("═════════════════════════════════════════")
tooltip_lines+=("$CPU_ICON_GENERAL | Type: $cpu_name")
tooltip_lines+=("-----------------------------------------")
tooltip_lines+=(" | Frequency: ${current_freq} MHz / ${max_freq} MHz")
tooltip_lines+=(" | Temperature: ${max_cpu_temp}°C")
tooltip_lines+=(" | Power: ${cpu_power} W")
tooltip_lines+=(" | Utilization: ${cpu_percent}%")
tooltip_lines+=("═════════════════════════════════════════")

# GPU Section
tooltip_lines+=("")
tooltip_lines+=("$GPU_ICON GPU:")
tooltip_lines+=("═════════════════════════════════════════")
tooltip_lines+=("$GPU_ICON | Type: $gpu_name")
tooltip_lines+=("-----------------------------------------")
tooltip_lines+=(" | Frequency: ${gpu_freq_current} MHz / ${gpu_freq_max} MHz")
tooltip_lines+=(" | Temperature: ${gpu_temp}°C")
tooltip_lines+=(" | Power: ${gpu_power} W")
tooltip_lines+=(" | Utilization: ${gpu_percent}%")
tooltip_lines+=("═════════════════════════════════════════")

# Memory Section
tooltip_lines+=("")
tooltip_lines+=("$MEM_ICON Memory:")
tooltip_lines+=("═════════════════════════════════════════")
tooltip_lines+=(" | Usage: ${mem_used_gb} / ${mem_total_gb} GB (${mem_percent}%)")

# Storage Section
if [ ${#storage_entries[@]} -gt 0 ]; then
    tooltip_lines+=("")
    tooltip_lines+=("$SSD_ICON Storage:")
    tooltip_lines+=("═════════════════════════════════════════")
    
    idx=0
    for entry in "${storage_entries[@]}"; do
        IFS=':' read -r icon label_full temp usage_percent <<< "$entry"
        
        # Short label
        label=$(echo "$label_full" | awk '{print $NF}')
        
        # Extract size
        size_match=$(echo "$label_full" | grep -o '[0-9]\+')
        if [ -n "$size_match" ]; then
            capacity_tb=$size_match
            capacity_str="${capacity_tb}TB"
        else
            capacity_str="1TB"
        fi
        
        # Usage
        if [ "$usage_percent" != "N/A" ]; then
            usage_tb=$(echo "scale=1; $capacity_tb * $usage_percent / 100" | bc)
            usage_percent_str="${usage_percent}%"
            if [ "$usage_percent" -lt 10 ]; then
                usage_percent_str="0${usage_percent}%"
            fi
            usage_str="$usage_tb TB ($usage_percent_str)"
        else
            usage_str="N/A"
        fi
        
        # Temperature
        if [ "$temp" != "N/A" ]; then
            temp_str="${temp}°C"
        else
            temp_str="N/A"
        fi
        
        line="$icon | $label $capacity_str | $usage_str | $temp_str"
        tooltip_lines+=("$line")
        ((idx++))
    done
    tooltip_lines+=("═════════════════════════════════════════")
fi

# Click hints
tooltip_lines+=("")
tooltip_lines+=("🖱️ LMB: Btop | 🖱️ RMB: CoolerControl")

# Build tooltip
tooltip=""
for line in "${tooltip_lines[@]}"; do
    if [ -z "$tooltip" ]; then
        tooltip="$line"
    else
        tooltip="$tooltip\n$line"
    fi
done

# Check click type and execute commands
click_type="$WAYBAR_CLICK_TYPE"
if [ "$click_type" = "left" ]; then
    # Try to find terminal
    TERMINAL="${TERMINAL:-$(
        which alacritty 2>/dev/null ||
        which kitty 2>/dev/null ||
        which gnome-terminal 2>/dev/null ||
        which xterm 2>/dev/null ||
        echo "xterm"
    )}"
    $TERMINAL -e btop &
elif [ "$click_type" = "right" ]; then
    /usr/bin/coolercontrol &
fi

# Output JSON with plain text (no markup)
cat << EOF
{
    "text": "$text",
    "tooltip": "$tooltip",
    "markup": "none",
    "click-events": true
}
EOF
