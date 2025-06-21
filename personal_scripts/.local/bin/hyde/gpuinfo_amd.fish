#!/usr/bin/env fish

# Get AMD GPU model
set amd_gpu (lspci -nn | grep -Ei "VGA|3D" | grep -m 1 "1002" | awk -F'Advanced Micro Devices, Inc. ' '{gsub(/ *\[[^\]]*\]/,""); gsub(/ *\([^)]*\)/,""); print $2}')

# Get the PCI address of the dGPU (second AMD VGA/3D controller)
set dgpu_pci (lspci -nn | grep -Ei "VGA|3D" | grep -i "AMD" | head -n2 | tail -n1 | awk '{print $1}')
# Convert PCI address to sensors label format (e.g., 03:00.0 -> 0300)
set dgpu_label (string replace -a ":" "" (string split "." $dgpu_pci)[1])
set dgpu_label "amdgpu-pci-0300"

# Now use this label to get temps from the correct section
set edge_temp (sensors | awk -v label="$dgpu_label" '/^$/ {f=0} $0 ~ label {f=1} f && /edge/ {print int($2); exit}')
set junction_temp (sensors | awk -v label="$dgpu_label" '/^$/ {f=0} $0 ~ label {f=1} f && /junction/ {print int($2); exit}')
set mem_temp (sensors | awk -v label="$dgpu_label" '/^$/ {f=0} $0 ~ label {f=1} f && /mem/ {print int($2); exit}')

# Use edge as the main temperature
set temperature $edge_temp

# Get utilization (using top if available, else fallback)
set utilization (top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{printf "%.1f", 100 - $1}')

# Get current clock speed (MHz)
set current_clock_speed 0
if test -d /sys/class/drm/card0/device
    if test -f /sys/class/drm/card0/device/pp_dpm_sclk
        set current_clock_speed (cat /sys/class/drm/card0/device/pp_dpm_sclk | grep '*' | awk '{print $2}' | grep -o '[0-9]*')
    end
end

# Get power usage (W) without tests
set power_usage 0
set raw_power (cat /sys/class/drm/card*/device/hwmon/hwmon*/power1_average 2>/dev/null | head -n1)
if set -q raw_power[1]
    set power_usage (math --scale 0 "$raw_power / 1000000")
end

# Use default icons/emojis
set temp_icon ""
set temp_emoji "❄️"
set util_icon "󰾆"
set power_icon "󱪉"
set clock_icon ""

# Compose output, handle empty temps gracefully
set text "$temp_icon $temperature°C"

# Compose tooltip without wrapping
set tooltip (string join "\n" \
    "$amd_gpu" \
    "$temp_icon Temperature: $temperature°C $temp_emoji" \
    "$temp_icon Junction: $junction_temp°C $temp_emoji" \
    "$temp_icon Memory: $mem_temp°C $temp_emoji" \
    "$util_icon Utilization: $utilization%" \
    "$power_icon Power Usage: $power_usage W" \
    "$clock_icon Clock Speed: $current_clock_speed MHz")

set json (string join '' '{"text":"' $text '", "tooltip":"' $tooltip '"}')
echo $json 