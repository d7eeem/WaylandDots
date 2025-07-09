#!/usr/bin/env bash

# Rofi Launcher Updater
# This script allows you to update rofi_launcher.sh from within rofi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER_FILE="$SCRIPT_DIR/rofi_launcher.sh"
LAUNCHERS_DIR="$SCRIPT_DIR/launchers"

# Function to get available launcher types
get_launcher_types() {
    find "$LAUNCHERS_DIR" -maxdepth 1 -type d -name "type-*" | sort | while read -r dir; do
        basename "$dir"
    done
}

# Function to get available themes for a launcher type
get_themes_for_type() {
    local launcher_type="$1"
    local theme_dir="$LAUNCHERS_DIR/$launcher_type"
    
    if [[ -d "$theme_dir" ]]; then
        find "$theme_dir" -maxdepth 1 -name "*.rasi" | sort | while read -r file; do
            basename "$file" .rasi
        done
    fi
}

# Function to update rofi_launcher.sh
update_launcher_file() {
    local launcher_type="$1"
    local theme="$2"
    
    # Create backup
    cp "$LAUNCHER_FILE" "${LAUNCHER_FILE}.backup"
    
    # Update the file
    sed -i "s|dir=\"\$HOME/.config/rofi/launchers/type-[0-9]*\"|dir=\"\$HOME/.config/rofi/launchers/$launcher_type\"|" "$LAUNCHER_FILE"
    sed -i "s|theme='[^']*'|theme='$theme'|" "$LAUNCHER_FILE"
    
    echo "Updated rofi_launcher.sh:"
    echo "  Launcher type: $launcher_type"
    echo "  Theme: $theme"
    echo "  Backup saved as: ${LAUNCHER_FILE}.backup"
}

# Main selection logic
if [[ "$1" == "select-type" ]]; then
    # Show launcher type selection
    selected_type=$(get_launcher_types | rofi -dmenu -p "Select Launcher Type:" -theme "$SCRIPT_DIR/config.rasi")
    
    if [[ -n "$selected_type" ]]; then
        # Show theme selection for the selected type
        selected_theme=$(get_themes_for_type "$selected_type" | rofi -dmenu -p "Select Theme for $selected_type:" -theme "$SCRIPT_DIR/config.rasi")
        
        if [[ -n "$selected_theme" ]]; then
            update_launcher_file "$selected_type" "$selected_theme"
        fi
    fi
else
    # Default behavior - show launcher type selection
    "$0" select-type
fi 