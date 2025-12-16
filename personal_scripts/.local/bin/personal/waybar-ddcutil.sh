#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

CACHE_FILE="/tmp/waybar_ddcutil_value"

# Get current brightness from monitor
output=$(ddcutil -t getvcp 10 2>/dev/null)

if [ $? -eq 0 ]; then
    # Parse the value from ddcutil output
    # Format: "VCP 10 C 50 100" -> extract current value (50)
    trimmed=${output#* * * }
    value=${trimmed%% *}
    
    # Read cached value
    cached_value=$(cat "$CACHE_FILE" 2>/dev/null)
    
    # Update cache only if value changed
    if [ "$cached_value" != "$value" ]; then
        echo "$value" > "$CACHE_FILE"
    fi
    
    # Output JSON for waybar
    echo "{\"percentage\": $value}"
else
    # ddcutil failed, use cached value or default to 0
    cached=$(cat "$CACHE_FILE" 2>/dev/null || echo 0)
    echo "{\"percentage\": $cached}"
fi
