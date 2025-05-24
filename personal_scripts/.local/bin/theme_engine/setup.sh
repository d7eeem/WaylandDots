#!/usr/bin/env bash

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Create directory structure
mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/"{gtk,hypr/hyprland,kde,swaync}
mkdir -p "$XDG_CACHE_HOME/theme_engine/user/generated/"{hypr,gtk,kde,swaync}
mkdir -p "$XDG_STATE_HOME/theme_engine/scss"
mkdir -p "$HOME/.local/share/color-schemes"
mkdir -p "$XDG_CONFIG_HOME/swaync"

# Copy template files
cp ./scripts/templates/hypr/hyprland/colors.conf "$XDG_CONFIG_HOME/theme_engine/scripts/templates/hypr/hyprland/"
cp ./scripts/templates/hypr/hyprlock.conf "$XDG_CONFIG_HOME/theme_engine/scripts/templates/hypr/"
cp ./scripts/templates/gtk/gtk-colors.css "$XDG_CONFIG_HOME/theme_engine/scripts/templates/gtk/"
cp ./scripts/templates/kde/theme.colors "$XDG_CONFIG_HOME/theme_engine/scripts/templates/kde/"
cp ./scripts/templates/swaync/style.css "$XDG_CONFIG_HOME/theme_engine/scripts/templates/swaync/"

# Copy scss file
cp ./scss/_material.scss "$XDG_STATE_HOME/theme_engine/scss/"

# Copy main script
cp ./theme_switcher.sh "$XDG_CONFIG_HOME/theme_engine/"
chmod +x "$XDG_CONFIG_HOME/theme_engine/theme_switcher.sh"

# Initial KDE color scheme setup if running under KDE
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]; then
    echo "KDE desktop detected, setting up color scheme..."
    cp ./scripts/templates/kde/theme.colors "$HOME/.local/share/color-schemes/MaterialYou.colors"
    if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
        plasma-apply-colorscheme MaterialYou
    fi
fi

# Initial swaync setup
if command -v swaync >/dev/null 2>&1; then
    echo "Swaync detected, setting up initial theme..."
    cp ./scripts/templates/swaync/style.css "$XDG_CONFIG_HOME/swaync/"
fi

echo "Setup complete! You can now use theme_switcher.sh"
echo "Usage: $XDG_CONFIG_HOME/theme_engine/theme_switcher.sh [path/to/wallpaper]" 