#!/usr/bin/env bash

# Get used RAM in GB
used_gb=$(free -g | awk '/Mem:/ {print $3}')
if [[ $used_gb -eq 0 ]]; then
  # If less than 1GB, show with decimals
  used_gb=$(free -m | awk '/Mem:/ {printf "%.1f", $3/1024}')
fi

# Get top memory-consuming processes
processes=$(ps axch -o cmd:15,%mem --sort -%mem | head)

# Escape newlines for JSON
processes_json=$(echo "$processes" | sed ':a;N;$!ba;s/\n/\\n/g')

# Output JSON for Waybar
json="{\"text\":\"${used_gb} GB\", \"tooltip\":\"${processes_json}\"}"
echo "$json" 