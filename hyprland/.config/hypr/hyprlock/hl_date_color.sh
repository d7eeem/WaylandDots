#!/bin/env bash


# Absolute path to your color config
COLOR_FILE="/home/tinker/.cache/wal/colors-hyprland.conf"

# Extract color7 and color4 from the Hyprland-style config
get_color() {
    grep "\$$1" "$COLOR_FILE" | sed -nE 's/.*rgb\(([0-9a-fA-F]+)\).*/#\1/p'
}

color7=$(get_color color7)
color4=$(get_color color4)

# Fallbacks if parsing fails
color7=${color7:-"#ffffff"}
color4=${color4:-"#aaaaaa"}

# Output Hyprlock-compatible formatted text
echo "<span color='${color7}'>$(date '+%A, ')</span><span color='${color4}'>$(date '+%d %B')</span>"

