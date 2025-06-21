#!/usr/bin/env fish

# Set default values for XDG directories if not set
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME $HOME/.cache
set -q XDG_STATE_HOME; or set -gx XDG_STATE_HOME $HOME/.local/state

# Create directory structure
mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/"{gtk,hypr/themes,kde,swaync}
mkdir -p "$XDG_CACHE_HOME/theme_engine/user/generated/"{hypr,gtk,kde,swaync}
mkdir -p "$XDG_STATE_HOME/theme_engine/scss"
mkdir -p "$HOME/.local/share/color-schemes"
mkdir -p "$XDG_CONFIG_HOME/swaync"

# Copy template files
cp ./scripts/templates/hypr/themes/colors.conf "$XDG_CONFIG_HOME/theme_engine/scripts/templates/hypr/themes/"
cp ./scripts/templates/hypr/hyprlock.conf "$XDG_CONFIG_HOME/theme_engine/scripts/templates/hypr/"
cp ./scripts/templates/gtk/gtk-colors.css "$XDG_CONFIG_HOME/theme_engine/scripts/templates/gtk/"
cp ./scripts/templates/kde/theme.colors "$XDG_CONFIG_HOME/theme_engine/scripts/templates/kde/"
cp ./scripts/templates/swaync/style.css "$XDG_CONFIG_HOME/theme_engine/scripts/templates/swaync/"

# Copy scss file
cp ./scss/_material.scss "$XDG_STATE_HOME/theme_engine/scss/"

# Copy main script
cp ./theme_switcher.fish "$XDG_CONFIG_HOME/theme_engine/"
chmod +x "$XDG_CONFIG_HOME/theme_engine/theme_switcher.fish"

# Initial KDE color scheme setup if running under KDE
if test "$XDG_CURRENT_DESKTOP" = "KDE" -o "$DESKTOP_SESSION" = "plasma"
    echo "KDE desktop detected, setting up color scheme..."
    cp ./scripts/templates/kde/theme.colors "$HOME/.local/share/color-schemes/MaterialYou.colors"
    if type -q plasma-apply-colorscheme
        plasma-apply-colorscheme MaterialYou
    end
end

# Initial swaync setup
if type -q swaync
    echo "Swaync detected, setting up initial theme..."
    cp ./scripts/templates/swaync/style.css "$XDG_CONFIG_HOME/swaync/"
end

echo "Setup complete! You can now use theme_switcher.fish"
echo "Usage: $XDG_CONFIG_HOME/theme_engine/theme_switcher.fish [path/to/wallpaper]" 