#!/usr/bin/env bash

# Simple Rofi Launcher Selector
# Run this script to change your rofi launcher type and theme

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
LAUNCHER_FILE="$SCRIPT_DIR/rofi_launcher.sh"
LAUNCHERS_DIR="$SCRIPT_DIR/launchers"

# Get all available launcher types and their themes
get_options() {
    for type_dir in "$LAUNCHERS_DIR"/type-*; do
        if [[ -d "$type_dir" ]]; then
            type=$(basename "$type_dir")
            for theme_file in "$type_dir"/*.rasi; do
                if [[ -f "$theme_file" ]]; then
                    theme=$(basename "$theme_file" .rasi)
                    echo "$type:$theme"
                fi
            done
        fi
    done
}

# Update the launcher file
update_launcher() {
    local selection="$1"
    local type="${selection%:*}"
    local theme="${selection#*:}"
    
    # Create backup
    cp "$LAUNCHER_FILE" "${LAUNCHER_FILE}.backup"
    
    # Update the file using sed
    sed -i "s|dir=\".*launchers/type-[^\"]*\"|dir=\"$LAUNCHERS_DIR/$type\"|" "$LAUNCHER_FILE"
    sed -i "s|theme='[^']*'|theme='$theme'|" "$LAUNCHER_FILE"
    
    # Show notification
    notify-send "Rofi Launcher Updated" "Type: $type\nTheme: $theme" -t 3000
}

# Main execution
options=$(get_options | sort)
selected=$(echo "$options" | rofi -dmenu -p "Select Launcher Type:Theme" -theme "$SCRIPT_DIR/config.rasi")

if [[ -n "$selected" ]]; then
    update_launcher "$selected"
fi 