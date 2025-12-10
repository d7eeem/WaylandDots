#!/bin/env bash
# Absolute path to your color config
COLOR_FILE="$HOME/.config/hypr/hyprlock/matugen-hyprlock.conf"

get_color() {
    local result=$(grep "^\$$1 = rgba(" "$COLOR_FILE" | head -n 1 | sed -nE 's/.*rgba\(([0-9a-fA-F]{6}).*/\1/p')
    if [[ -n "$result" ]]; then
        echo "#$result"
    fi
}

color7=$(get_color primary_fixed)
color4=$(get_color primary_fixed_dim)

# Fallbacks if parsing fails
color7=${color7:-"#b2cfa8"}
color4=${color4:-"#ebc06c"}

# Output Hyprlock-compatible formatted text
echo "<span color='${color7}'>$(date '+%A, ')</span><span color='${color4}'>$(date '+%d %B')</span>"
