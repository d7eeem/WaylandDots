#!/usr/bin/env bash

set -x

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/theme_engine"
CACHE_DIR="$XDG_CACHE_HOME/theme_engine"
STATE_DIR="$XDG_STATE_HOME/theme_engine"
STYLE_WAYBAR="${STYLE_WAYBAR:-true}"  # Default to true, can be overridden by environment variable

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
        # Remove the $ prefix from color names and ensure proper color value handling
        color_name=${colorlist[$i]#$}
        color_value=${colorvalues[$i]#\#}
        # Handle both formats: with and without # prefix
        sed -i "s/#{{ ${color_name} }}/#${color_value}/g" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
        sed -i "s/{{ ${color_name} }}/${color_value}/g" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
    done
    
    # Apply the config
    cp "$CACHE_DIR/user/generated/hypr/hyprlock.conf" "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
}

apply_gtk() {
    if [ ! -f "$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css" ]; then
        echo "Template file not found for gtk colors. Skipping that."
        return
    fi
    
    # Get current GTK theme and color scheme
    current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
    current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
    
    # Copy and process template
    cp "$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
    
    # First pass: Replace all direct color values
    for i in "${!colorlist[@]}"; do
        # Remove the $ prefix from color names and ensure proper color value handling
        color_name=${colorlist[$i]#$}
        color_value=${colorvalues[$i]#\#}
        
        # Replace both formats of color variables
        sed -i "s/#{{ ${color_name} }}/#${color_value}/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
        sed -i "s/@{{ ${color_name} }}/@${color_value}/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
        sed -i "s/{{ ${color_name} }}/${color_value}/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
    done
    
    # Second pass: Process any remaining CSS variable references
    processed_file=$(cat "$CACHE_DIR/user/generated/gtk/gtk-colors.css")
    while IFS= read -r line; do
        if [[ $line =~ @define-color[[:space:]]+([^[:space:]]+)[[:space:]]+@([^[:space:]]+) ]]; then
            var_name="${BASH_REMATCH[1]}"
            ref_var="${BASH_REMATCH[2]}"
            # Find the value of the referenced variable
            ref_value=$(echo "$processed_file" | grep -oP "@define-color\s+${ref_var}\s+\K[^;]+")
            if [ ! -z "$ref_value" ]; then
                sed -i "s|@define-color[[:space:]]\+${var_name}[[:space:]]\+@${ref_var}|@define-color ${var_name} ${ref_value}|g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
            fi
        fi
    done < "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
    
    # Ensure directories exist
    mkdir -p "$XDG_CONFIG_HOME/gtk-3.0"
    mkdir -p "$XDG_CONFIG_HOME/gtk-4.0"
    
    # Apply to both gtk3 and gtk4
    cp "$CACHE_DIR/user/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
    cp "$CACHE_DIR/user/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"
    
    # First, set a temporary theme to force reload
    gsettings set org.gnome.desktop.interface gtk-theme ''
    
    # Set the color scheme
    if [[ "$current_theme" == *"dark"* ]] || [[ "$current_scheme" == *"prefer-dark"* ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    fi
    
    # Force GTK to reload the theme
    gtk-update-icon-cache -f -t ~/.local/share/icons/default 2>/dev/null || true
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

apply_swaync() {
    if [ ! -f "$CONFIG_DIR/scripts/templates/swaync/style.css" ]; then
        echo "Template file not found for swaync. Skipping that."
        return
    fi
    
    # Create necessary directories
    mkdir -p "$CACHE_DIR/user/generated/swaync"
    mkdir -p "$XDG_CONFIG_HOME/swaync"
    
    # Copy template
    cp "$CONFIG_DIR/scripts/templates/swaync/style.css" "$CACHE_DIR/user/generated/swaync/style.css"
    
    # Replace color variables
    for i in "${!colorlist[@]}"; do
        # Remove the $ prefix from color names
        color_name=${colorlist[$i]#$}
        color_value=${colorvalues[$i]#\#}
        
        # Replace both formats of color variables (with and without #)
        sed -i "s/@define-color ${color_name} .*/@define-color ${color_name} #${color_value}/g" "$CACHE_DIR/user/generated/swaync/style.css"
    done
    
    # Apply the config
    cp "$CACHE_DIR/user/generated/swaync/style.css" "$XDG_CONFIG_HOME/swaync/style.css"
    
    # Reload swaync if it's running
    if pgrep -x "swaync" > /dev/null; then
        pkill -USR2 swaync
    fi
}

apply_waybar() {
    # Skip if waybar styling is disabled
    if [ "$STYLE_WAYBAR" = "false" ]; then
        echo "Waybar styling is disabled. Skipping..."
        return
    fi

    # Ensure waybar config directory exists
    WAYBAR_CONFIG_DIR="$XDG_CONFIG_HOME/waybar"
    mkdir -p "$WAYBAR_CONFIG_DIR/modules"

    # Read colors from wal's SCSS file
    if [ -f "$HOME/.cache/wal/colors.scss" ]; then
        background=$(grep '^\$background:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
        foreground=$(grep '^\$foreground:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
        color12=$(grep '^\$color12:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
    else
        echo "Warning: wal colors.scss not found, using fallback colors"
        background="#000000"
        foreground="#ffffff"
    fi

    # Create theme.css with our colors
    cat > "$WAYBAR_CONFIG_DIR/theme.css" << EOF
@define-color foreground ${foreground};
@define-color background ${background};

@define-color main-bg ${background};
@define-color main-fg ${foreground};

@define-color wb-act-bg ${foreground};
@define-color wb-act-fg ${background};

@define-color wb-hvr-bg ${color12};
@define-color wb-hvr-fg ${foreground};

* {
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.5);
    font-weight: bold;
}
EOF

    # Run wbarconfgen.sh to generate the configuration
    if [ -f "$CONFIG_DIR/hyde/wbarconfgen.sh" ]; then
        sh "$CONFIG_DIR/hyde/wbarconfgen.sh"
    fi
}

apply_flatpak() {
    echo "Applying theme to Flatpak applications..."

    # Check if flatpak is installed
    if ! command -v flatpak >/dev/null 2>&1; then
        echo "Flatpak is not installed. Skipping Flatpak theming."
        return
    fi

    # Create Flatpak override directory if it doesn't exist
    FLATPAK_CONFIG_DIR="$HOME/.var/app"
    mkdir -p "$FLATPAK_CONFIG_DIR"

    # Get list of installed Flatpak apps
    while IFS= read -r app; do
        if [ ! -z "$app" ]; then
            echo "Processing Flatpak app: $app"
            
            # Create GTK config directories
            app_gtk3_dir="$FLATPAK_CONFIG_DIR/$app/config/gtk-3.0"
            app_gtk4_dir="$FLATPAK_CONFIG_DIR/$app/config/gtk-4.0"
            mkdir -p "$app_gtk3_dir"
            mkdir -p "$app_gtk4_dir"

            # Copy GTK theme files
            if [ -f "$XDG_CONFIG_HOME/gtk-3.0/gtk.css" ]; then
                echo "Copying GTK3 theme to: $app_gtk3_dir"
                cp -f "$XDG_CONFIG_HOME/gtk-3.0/gtk.css" "$app_gtk3_dir/"
            fi

            if [ -f "$XDG_CONFIG_HOME/gtk-4.0/gtk.css" ]; then
                echo "Copying GTK4 theme to: $app_gtk4_dir"
                cp -f "$XDG_CONFIG_HOME/gtk-4.0/gtk.css" "$app_gtk4_dir/"
            fi

            # Handle Waybar theme if present
            app_waybar_dir="$FLATPAK_CONFIG_DIR/$app/config/waybar"
            if [ -d "$app_waybar_dir" ]; then
                echo "Found Waybar config for $app, copying theme"
                cp -f "$XDG_CONFIG_HOME/waybar/theme.css" "$app_waybar_dir/"
            fi

            # Create GTK settings override
            gtk_settings_dir="$FLATPAK_CONFIG_DIR/$app/config/gtk-3.0"
            mkdir -p "$gtk_settings_dir"
            cat > "$gtk_settings_dir/settings.ini" << EOL
[Settings]
gtk-theme-name=adw-gtk3
gtk-application-prefer-dark-theme=true
gtk-font-name=Cantarell 11
EOL
        fi
    done < <(flatpak list --app --columns=application)

    # Override global Flatpak GTK theme
    mkdir -p "$HOME/.local/share/flatpak/overrides"
    cat > "$HOME/.local/share/flatpak/overrides/global" << EOL
[Environment]
GTK_THEME=adw-gtk3
ICON_THEME=Papirus-Dark
EOL

    echo "Flatpak theme application completed"
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
    /usr/bin/matugen image  "$imgpath"
    cp "$imgpath" "$HOME/.config/rofi/images/background.png"
    
    # Wait for pywal to finish and create the cache
    sleep 0.5
    
    # Read colors from wal's SCSS file
    if [ -f "$HOME/.cache/wal/colors.scss" ]; then
        # Extract colors from wal's SCSS
        background=$(grep '^\$background:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
        foreground=$(grep '^\$foreground:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
        cursor=$(grep '^\$cursor:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
        
        # Extract color0-15
        for i in {0..15}; do
            color[$i]=$(grep "^\$color${i}:" "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
        done
        
        # Create or overwrite _material.scss with new colors
        cat > "$STATE_DIR/scss/_material.scss" << EOF
\$rosewater: ${color[6]};
\$flamingo: ${color[7]};
\$pink: ${color[5]};
\$mauve: ${color[4]};
\$red: ${color[1]};
\$maroon: ${color[2]};
\$peach: ${color[3]};
\$yellow: ${color[3]};
\$green: ${color[2]};
\$teal: ${color[4]};
\$sky: ${color[4]};
\$sapphire: ${color[4]};
\$blue: ${color[4]};
\$lavender: ${color[5]};
\$text: ${foreground};
\$subtext1: ${foreground};
\$subtext0: ${foreground};
\$overlay2: ${foreground};
\$overlay1: ${foreground};
\$overlay0: ${foreground};
\$surface2: ${background};
\$surface1: ${background};
\$surface0: ${background};
\$base: ${background};
\$mantle: ${background};
\$crust: ${background};
\$accent: ${color[4]}; 
EOF
    else
        echo "Error: wal colors.scss not found"
        exit 1
    fi

    # Load colors from material.scss for other theme applications
    colornames=$(cat "$STATE_DIR/scss/_material.scss" | cut -d: -f1)
    colorstrings=$(cat "$STATE_DIR/scss/_material.scss" | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
    IFS=$'\n'
    colorlist=($colornames)
    colorvalues=($colorstrings)

apply_cache() {
    magick "${imgpath}[0]" -strip -resize 1000 -gravity center -extent 1000 -quality 90 "/home/tinker/.cache/theme_engine/wall.thmb"
    magick "${imgpath}[0]" -strip -thumbnail 500x500^ -gravity center -extent 500x500 "/home/tinker/.cache/theme_engine/wall.sqre"
    magick "${imgpath}[0]" -strip -scale 10% -blur 0x3 -resize 100% "/home/tinker/.cache/theme_engine/wall.blur"
}

    Apply themes
    apply_hyprland &
    apply_hyprlock &
    apply_gtk &
    # apply_qt &
    apply_swaync &
    apply_waybar &
    apply_flatpak &
    apply_cache & 
}

# Main script execution
if [[ "$1" ]]; then
    switch "$1"
else
    # Select and set image using appropriate file picker
    cd "$(xdg-user-dir HOME)/Nextcloud/Wallpapers" || cd "$(xdg-user-dir PICTURES)" || exit 1
    switch "$(open_file_picker)"
fi 
