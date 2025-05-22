#!/usr/bin/env bash

set -x

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/theme_engine"
CACHE_DIR="$XDG_CACHE_HOME/theme_engine"
STATE_DIR="$XDG_STATE_HOME/theme_engine"

# Create necessary directories
mkdir -p "$CACHE_DIR"/user/generated/{hypr,gtk}
mkdir -p "$STATE_DIR"/scss

# Initialize color arrays
colornames=''
colorstrings=''
colorlist=()
colorvalues=()

# Function to check if running under KDE
is_kde() {
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]; then
        return 0
    else
        return 1
    fi
}

# Function to open file picker based on environment
open_file_picker() {
    if is_kde; then
        kdialog --title "Choose Wallpaper" --getimage
    elif command -v yad >/dev/null 2>&1; then
        yad --width 1200 --height 800 --file --add-preview --large-preview --title='Choose wallpaper'
    else
        echo "No supported file picker found. Please install yad or kdialog."
        exit 1
    fi
}

# Get cursor position and screen information for transition effect
get_cursor_pos() {
    read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
    cursorposx=$(hyprctl cursorpos -j | jq '.x' 2>/dev/null) || cursorposx=960
    cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
    cursorposy=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null) || cursorposy=540
    cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
    cursorposy_inverted=$((screensizey - cursorposy))
}

apply_hyprland() {
    if [ ! -f "$CONFIG_DIR/scripts/templates/hypr/hyprland/colors.conf" ]; then
        echo "Template file not found for Hyprland colors. Skipping that."
        return
    fi
    
    # Copy template
    cp "$CONFIG_DIR/scripts/templates/hypr/hyprland/colors.conf" "$CACHE_DIR/user/generated/hypr/colors.conf"
    
    # Replace color variables
    for i in "${!colorlist[@]}"; do
        # Remove the $ prefix from color names
        color_name=${colorlist[$i]#$}
        color_value=${colorvalues[$i]#\#}
        
        # Replace in variable declarations
        sed -i "s/{{ ${color_name} }}/${color_value}/g" "$CACHE_DIR/user/generated/hypr/colors.conf"
        
        # Replace in rgba() functions
        sed -i "s/rgba({{ ${color_name} }}ff)/rgba(${color_value}ff)/g" "$CACHE_DIR/user/generated/hypr/colors.conf"
        sed -i "s/rgba({{ ${color_name} }}cc)/rgba(${color_value}cc)/g" "$CACHE_DIR/user/generated/hypr/colors.conf"
    done
    
    # Copy to hyprland config
    cp "$CACHE_DIR/user/generated/hypr/colors.conf" "$XDG_CONFIG_HOME/hypr/hyprland/colors.conf"
}

apply_hyprlock() {
    if [ ! -f "$CONFIG_DIR/scripts/templates/hypr/hyprlock.conf" ]; then
        echo "Template file not found for hyprlock. Skipping that."
        return
    fi
    
    # Get current wallpaper path
    current_wall=$(swww query | head -1 | awk -F 'image: ' '{print $2}')
    
    # Copy template
    cp "$CONFIG_DIR/scripts/templates/hypr/hyprlock.conf" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
    
    # Replace colors and wallpaper path
    sed -i "s|path = .*|path = $current_wall|" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ ${colorlist[$i]} }}/${colorvalues[$i]#\#}/g" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
    done
    
    # Apply the config
    cp "$CACHE_DIR/user/generated/hypr/hyprlock.conf" "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
}

apply_gtk() {
    if [ ! -f "$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css" ]; then
        echo "Template file not found for gtk colors. Skipping that."
        return
    fi
    
    # Get current GTK theme
    current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
    
    # Copy and process template
    cp "$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ ${colorlist[$i]} }}/#${colorvalues[$i]#\#}/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
    done
    
    # Apply to both gtk3 and gtk4
    cp "$CACHE_DIR/user/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
    cp "$CACHE_DIR/user/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"
    
    # Keep the current theme (light/dark) state
    if [[ "$current_theme" == *"-dark"* ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    else
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    fi
}

apply_qt() {
    # Apply Kvantum theme if available
    if [ -f "$CONFIG_DIR/scripts/kvantum/materialQT.sh" ]; then
        sh "$CONFIG_DIR/scripts/kvantum/materialQT.sh"
    fi
    if [ -f "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py" ]; then
        python "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py"
    fi
    
    # Update KDE color scheme
    if is_kde; then
        # Create KDE color scheme directory
        mkdir -p "$HOME/.local/share/color-schemes"
        
        # Copy and process the color scheme template
        cp "$CONFIG_DIR/scripts/templates/kde/theme.colors" "$CACHE_DIR/user/generated/kde/theme.colors"
        
        # Replace color variables
        for i in "${!colorlist[@]}"; do
            color_name=${colorlist[$i]#$}
            color_value=${colorvalues[$i]#\#}
            sed -i "s/{{ ${color_name} }}/${color_value}/g" "$CACHE_DIR/user/generated/kde/theme.colors"
        done
        
        # Install the color scheme
        cp "$CACHE_DIR/user/generated/kde/theme.colors" "$HOME/.local/share/color-schemes/MaterialYou.colors"
        
        # Apply the color scheme
        plasma-apply-colorscheme MaterialYou
        
        # Reload Dolphin if it's running
        if pgrep -x "dolphin" > /dev/null; then
            killall dolphin
            dolphin &
        fi
    fi
}

# Function to switch wallpaper and generate colors
switch() {
    imgpath=$1
    
    if [ "$imgpath" == '' ]; then
        echo 'Aborted'
        exit 0
    fi

    # Get cursor position for transition
    get_cursor_pos

    # Set wallpaper with swww
    swww img "$imgpath" --transition-step 100 --transition-fps 120 \
        --transition-type grow --transition-angle 30 --transition-duration 1 \
        --transition-pos "$cursorposx, $cursorposy_inverted"

    # Generate color scheme with pywal
    wal -i "$imgpath"

    # Load colors from material.scss
    colornames=$(cat "$STATE_DIR/scss/_material.scss" | cut -d: -f1)
    colorstrings=$(cat "$STATE_DIR/scss/_material.scss" | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
    IFS=$'\n'
    colorlist=($colornames)
    colorvalues=($colorstrings)

    # Apply themes
    apply_hyprland &
    apply_hyprlock &
    apply_gtk &
    apply_qt &
}

# Main script execution
if [[ "$1" ]]; then
    switch "$1"
else
    # Select and set image using appropriate file picker
    cd "$(xdg-user-dir HOME)/Nextcloud/Wallpapers" || cd "$(xdg-user-dir PICTURES)" || exit 1
    switch "$(open_file_picker)"
fi 