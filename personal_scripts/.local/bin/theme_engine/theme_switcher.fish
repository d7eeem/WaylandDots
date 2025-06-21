#!/usr/bin/env fish

# Set default values for XDG directories if not set
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME $HOME/.cache
set -q XDG_STATE_HOME; or set -gx XDG_STATE_HOME $HOME/.local/state
set -q STYLE_WAYBAR; or set -gx STYLE_WAYBAR true

# Set directory variables
set -l CONFIG_DIR "$XDG_CONFIG_HOME/theme_engine"
set -l CACHE_DIR "$XDG_CACHE_HOME/theme_engine"
set -l STATE_DIR "$XDG_STATE_HOME/theme_engine"

# Create necessary directories
mkdir -p "$CACHE_DIR"/user/generated/{hypr,gtk}
mkdir -p "$STATE_DIR"/scss

# Initialize color arrays
set -l colornames
set -l colorstrings
set -l colorlist
set -l colorvalues

# Function to check if running under KDE
function is_kde
    if test "$XDG_CURRENT_DESKTOP" = "KDE" -o "$DESKTOP_SESSION" = "plasma"
        return 0
    else
        return 1
    end
end

# Function to open file picker based on environment
function open_file_picker
    if is_kde
        kdialog --title "Choose Wallpaper" --getimage
    else if type -q yad
        yad --width 1200 --height 800 --file --add-preview --large-preview --title='Choose wallpaper'
    else
        echo "No supported file picker found. Please install yad or kdialog."
        exit 1
    end
end

# Get cursor position and screen information for transition effect
function get_cursor_pos
    set -l monitor_info (hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
    set -l scale $monitor_info[1]
    set -l screenx $monitor_info[2]
    set -l screeny $monitor_info[3]
    set -l screensizey $monitor_info[4]
    
    set -l cursorposx (hyprctl cursorpos -j | jq '.x' 2>/dev/null; or echo 960)
    set -l cursorposy (hyprctl cursorpos -j | jq '.y' 2>/dev/null; or echo 540)
    
    set -l cursorposx (math "scale=0; ($cursorposx - $screenx) * $scale / 1")
    set -l cursorposy (math "scale=0; ($cursorposy - $screeny) * $scale / 1")
    set -l cursorposy_inverted (math "$screensizey - $cursorposy")
end

# Apply Hyprland theme
function apply_hyprland
    if not test -f "$CONFIG_DIR/scripts/templates/hypr/themes/colors.conf"
        echo "Template file not found for Hyprland colors. Skipping that."
        return
    end

    # Copy template
    cp "$CONFIG_DIR/scripts/templates/hypr/themes/colors.conf" "$CACHE_DIR/user/generated/hypr/colors.conf"

    # Replace color variables
    for i in (seq (count $colorlist))
        # Remove the $ prefix from color names
        set -l color_name (string replace -r '^\$' '' $colorlist[$i])
        set -l color_value (string replace -r '^#' '' $colorvalues[$i])

        # Replace in variable declarations
        sed -i "s/{{ $color_name }}/$color_value/g" "$CACHE_DIR/user/generated/hypr/colors.conf"

        # Replace in rgba() functions
        sed -i "s/rgba({{ $color_name }}ff)/rgba($color_value"ff")/g" "$CACHE_DIR/user/generated/hypr/colors.conf"
        sed -i "s/rgba({{ $color_name }}cc)/rgba($color_value"cc")/g" "$CACHE_DIR/user/generated/hypr/colors.conf"
    end

    # Copy to hyprland config
    cp "$CACHE_DIR/user/generated/hypr/colors.conf" "$XDG_CONFIG_HOME/hypr/themes/colors.conf"
end

# Apply hyprlock theme
function apply_hyprlock
    if not test -f "$CONFIG_DIR/scripts/templates/hypr/hyprlock.conf"
        echo "Template file not found for hyprlock. Skipping that."
        return
    end

    # Get current wallpaper path
    set -l current_wall (swww query | head -1 | awk -F 'image: ' '{print $2}')

    # Copy template
    cp "$CONFIG_DIR/scripts/templates/hypr/hyprlock.conf" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"

    # Replace colors and wallpaper path
    sed -i "s|path = .*|path = $current_wall|" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
    for i in (seq (count $colorlist))
        # Remove the $ prefix from color names and ensure proper color value handling
        set -l color_name (string replace -r '^\$' '' $colorlist[$i])
        set -l color_value (string replace -r '^#' '' $colorvalues[$i])
        # Handle both formats: with and without # prefix
        sed -i "s/#{{ $color_name }}/#$color_value/g" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
        sed -i "s/{{ $color_name }}/$color_value/g" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
    end

    # Apply the config
    cp "$CACHE_DIR/user/generated/hypr/hyprlock.conf" "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
end

# Apply GTK theme
function apply_gtk
    if not test -f "$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css"
        echo "Template file not found for gtk colors. Skipping that."
        return
    end

    # Get current GTK theme and color scheme
    set -l current_theme (gsettings get org.gnome.desktop.interface gtk-theme)
    set -l current_scheme (gsettings get org.gnome.desktop.interface color-scheme)

    # Copy and process template
    cp "$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"

    # First pass: Replace all direct color values
    for i in (seq (count $colorlist))
        # Remove the $ prefix from color names and ensure proper color value handling
        set -l color_name (string replace -r '^\$' '' $colorlist[$i])
        set -l color_value (string replace -r '^#' '' $colorvalues[$i])

        # Replace both formats of color variables
        sed -i "s/#{{ $color_name }}/#$color_value/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
        sed -i "s/@{{ $color_name }}/@$color_value/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
        sed -i "s/{{ $color_name }}/$color_value/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
    end

    # Second pass: Process any remaining CSS variable references
    set -l processed_file (cat "$CACHE_DIR/user/generated/gtk/gtk-colors.css")
    while read -l line
        if string match -q -r '@define-color\s+([^\s]+)\s+@([^\s]+)' "$line"
            set -l var_name (string match -r '@define-color\s+([^\s]+)\s+@([^\s]+)' "$line" | string replace -r '@define-color\s+([^\s]+)\s+@([^\s]+)' '$1')
            set -l ref_var (string match -r '@define-color\s+([^\s]+)\s+@([^\s]+)' "$line" | string replace -r '@define-color\s+([^\s]+)\s+@([^\s]+)' '$2')
            # Find the value of the referenced variable
            set -l ref_value (echo "$processed_file" | grep -oP "@define-color\s+$ref_var\s+\K[^;]+")
            if test -n "$ref_value"
                sed -i "s|@define-color[[:space:]]\+$var_name[[:space:]]\+@$ref_var|@define-color $var_name $ref_value|g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
            end
        end
    end < "$CACHE_DIR/user/generated/gtk/gtk-colors.css"

    # Ensure directories exist
    mkdir -p "$XDG_CONFIG_HOME/gtk-3.0"
    mkdir -p "$XDG_CONFIG_HOME/gtk-4.0"

    # Apply to both gtk3 and gtk4
    cp "$CACHE_DIR/user/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
    cp "$CACHE_DIR/user/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"

    # First, set a temporary theme to force reload
    gsettings set org.gnome.desktop.interface gtk-theme ''

    # Set the color scheme
    if string match -q "*dark*" "$current_theme" -o string match -q "*prefer-dark*" "$current_scheme"
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'Everforest-Dark'
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'Everforest-Dark'
    end

    # Force GTK to reload the theme
    gtk-update-icon-cache -f -t ~/.local/share/icons/default 2>/dev/null; or true
end

# Apply swaync theme
function apply_swaync
    if not test -f "$CONFIG_DIR/scripts/templates/swaync/style.css"
        echo "Template file not found for swaync. Skipping that."
        return
    end

    # Create necessary directories
    mkdir -p "$CACHE_DIR/user/generated/swaync"
    mkdir -p "$XDG_CONFIG_HOME/swaync"

    # Copy template
    cp "$CONFIG_DIR/scripts/templates/swaync/style.css" "$CACHE_DIR/user/generated/swaync/style.css"

    # Replace color variables
    for i in (seq (count $colorlist))
        # Remove the $ prefix from color names
        set -l color_name (string replace -r '^\$' '' $colorlist[$i])
        set -l color_value (string replace -r '^#' '' $colorvalues[$i])

        # Replace both formats of color variables (with and without #)
        sed -i "s/@define-color $color_name .*/@define-color $color_name #$color_value/g" "$CACHE_DIR/user/generated/swaync/style.css"
    end

    # Apply the config
    cp "$CACHE_DIR/user/generated/swaync/style.css" "$XDG_CONFIG_HOME/swaync/style.css"

    # Reload swaync if it's running
    if pgrep -x "swaync" >/dev/null
        pkill -USR2 swaync
    end
end

# Apply Waybar theme
function apply_waybar
    # Skip if waybar styling is disabled
    if test "$STYLE_WAYBAR" = "false"
        echo "Waybar styling is disabled. Skipping..."
        return
    end

    # Ensure waybar config directory exists
    set -l WAYBAR_CONFIG_DIR "$XDG_CONFIG_HOME/waybar"
    mkdir -p "$WAYBAR_CONFIG_DIR/modules"
end

# Main theme application function
function apply_theme
    # Apply themes in order
    apply_hyprland
    apply_hyprlock
    apply_gtk
    apply_swaync
    apply_waybar
end

# Main script execution
if test (count $argv) -eq 0
    # No arguments provided, use file picker
    set -l wallpaper (open_file_picker)
    if test -n "$wallpaper"
        wal -i "$wallpaper" -n
        apply_theme
    end
else
    # Use provided wallpaper
    wal -i "$argv[1]" -n
    apply_theme
end 