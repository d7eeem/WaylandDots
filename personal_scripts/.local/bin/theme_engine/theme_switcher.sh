#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Theme Switcher - Wallpaper-based theme engine for Hyprland on GNOME
# ============================================================================

# ------------ Configuration ------------
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$SCRIPT_DIR"
readonly CACHE_DIR="$XDG_CACHE_HOME/theme_engine"
readonly STATE_DIR="$XDG_STATE_HOME/theme_engine"

# Default GTK theme
readonly DEFAULT_GTK_THEME="WhiteSur-Dark-solid-alt-red-nord"

# Theme variants in priority order (your theme first)
readonly THEME_VARIANTS=(
    "$DEFAULT_GTK_THEME"
    "WhiteSur-Dark-solid-orange"
    "WhiteSur-Dark-solid-blue" 
    "WhiteSur-Dark-solid-purple"
    "WhiteSur-Dark-solid"
    "WhiteSur-Dark-orange"
    "WhiteSur-Dark-blue"
    "WhiteSur-Dark-purple"
    "WhiteSur-Dark"
    "Adwaita-dark"
    "Yaru-dark"
)

# Theme search paths
readonly THEME_PATHS=(
    "$HOME/.themes"
    "$HOME/.local/share/themes"
    "/usr/share/themes"
)

# Color lists (populated by switch function)
declare -a colorlist=()
declare -a colorvalues=()

# Backup of original theme settings
declare -gA original_settings=()

# ------------ Directory Setup ------------
init_directories() {
    mkdir -p "$CACHE_DIR/user/generated/"{hypr,gtk,swaync}
    mkdir -p "$STATE_DIR/scss"
    mkdir -p "$CACHE_DIR/gtk"
}

# ------------ Utility Functions ------------
is_gnome() {
    [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || [[ "$XDG_SESSION_DESKTOP" == *"gnome"* ]] || [[ "$GDMSESSION" == *"gnome"* ]]
}

is_hyprland() {
    [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]] || [[ "$XDG_SESSION_DESKTOP" == *"hyprland"* ]] || pgrep -x hyprland >/dev/null
}

theme_exists() {
    local theme="$1"
    for path in "${THEME_PATHS[@]}"; do
        [[ -d "$path/$theme" ]] && return 0
    done
    return 1
}

detect_dark_theme() {
    # Always prefer the default theme if it exists
    if theme_exists "$DEFAULT_GTK_THEME"; then
        echo "$DEFAULT_GTK_THEME"
        return 0
    fi
    
    # Fallback to other themes
    for variant in "${THEME_VARIANTS[@]}"; do
        if theme_exists "$variant"; then
            echo "$variant"
            return 0
        fi
    done
    echo "Adwaita-dark"
}

backup_original_theme() {
    echo "Backing up current theme settings..." >&2
    
    # Backup dconf settings
    if command -v dconf >/dev/null 2>&1; then
        original_settings["gtk-theme"]=$(dconf read /org/gnome/desktop/interface/gtk-theme 2>/dev/null || echo "''")
        original_settings["color-scheme"]=$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null || echo "''")
        original_settings["icon-theme"]=$(dconf read /org/gnome/desktop/interface/icon-theme 2>/dev/null || echo "''")
        original_settings["cursor-theme"]=$(dconf read /org/gnome/desktop/interface/cursor-theme 2>/dev/null || echo "''")
    fi
    
    # Backup gsettings
    if command -v gsettings >/dev/null 2>&1; then
        original_settings["gsettings-gtk-theme"]=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "")
        original_settings["gsettings-color-scheme"]=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "")
    fi
    
    echo "Original settings backed up" >&2
}

restore_original_theme() {
    echo "Restoring original theme settings..." >&2
    
    # Restore dconf settings
    if command -v dconf >/dev/null 2>&1; then
        if [[ -n "${original_settings["gtk-theme"]}" ]]; then
            dconf write /org/gnome/desktop/interface/gtk-theme "${original_settings["gtk-theme"]}" 2>/dev/null || true
        fi
        if [[ -n "${original_settings["color-scheme"]}" ]]; then
            dconf write /org/gnome/desktop/interface/color-scheme "${original_settings["color-scheme"]}" 2>/dev/null || true
        fi
        if [[ -n "${original_settings["icon-theme"]}" ]]; then
            dconf write /org/gnome/desktop/interface/icon-theme "${original_settings["icon-theme"]}" 2>/dev/null || true
        fi
        if [[ -n "${original_settings["cursor-theme"]}" ]]; then
            dconf write /org/gnome/desktop/interface/cursor-theme "${original_settings["cursor-theme"]}" 2>/dev/null || true
        fi
    fi
    
    # Restore gsettings
    if command -v gsettings >/dev/null 2>&1; then
        if [[ -n "${original_settings["gsettings-gtk-theme"]}" ]]; then
            gsettings set org.gnome.desktop.interface gtk-theme "${original_settings["gsettings-gtk-theme"]}" 2>/dev/null || true
        fi
        if [[ -n "${original_settings["gsettings-color-scheme"]}" ]]; then
            gsettings set org.gnome.desktop.interface color-scheme "${original_settings["gsettings-color-scheme"]}" 2>/dev/null || true
        fi
    fi
    
    echo "Original theme restored" >&2
}

setup_systemwide_dark_mode() {
    local dark_theme="$1"
    
    echo "Setting systemwide dark mode: $dark_theme" >&2
    
    # Use dconf for systemwide theming (most reliable)
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/gnome/desktop/interface/gtk-theme "'$dark_theme'" 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/icon-theme "'WhiteSur-dark'" 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/cursor-theme "'WhiteSur-cursors'" 2>/dev/null || true
        
        # Additional dark mode settings
        dconf write /org/gnome/desktop/interface/enable-animations true 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/clock-format "'24h'" 2>/dev/null || true
        
        echo "Applied dconf dark mode settings" >&2
    fi
    
    # Also set via gsettings for compatibility
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme "$dark_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors' 2>/dev/null || true
        
        echo "Applied gsettings dark mode settings" >&2
    fi
    
    # Create GTK config files as backup
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=$dark_theme
gtk-icon-theme-name=WhiteSur-dark
gtk-font-name=Ubuntu, 11
gtk-cursor-theme-name=WhiteSur-cursors
gtk-enable-animations=1
EOF

    cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
    
    # Small delay to ensure theme changes take effect
    sleep 1
}

setup_dark_environment() {
    local dark_theme
    dark_theme="$(detect_dark_theme)"
    
    # Backup current theme before making changes
    backup_original_theme
    
    # Apply systemwide dark mode
    setup_systemwide_dark_mode "$dark_theme"
    
    # Set environment variables for current process
    export GTK_THEME="$dark_theme"
    export QT_QPA_PLATFORMTHEME="gtk3"
    export XDG_CURRENT_DESKTOP="GNOME"
    export GTK_APPLICATION_PREFER_DARK_THEME=1
    
    echo "Dark environment configured with: $dark_theme" >&2
}

open_file_picker() {
    local selected_file=""
    
    # Setup systemwide dark environment
    setup_dark_environment
    
    echo "Opening file picker with system dark theme..." >&2
    
    # Try yad first
    if command -v yad >/dev/null 2>&1; then
        echo "Using yad file picker..." >&2
        selected_file=$(yad --file \
            --width=1200 \
            --height=800 \
            --title="Choose Wallpaper" \
            --text="Select an image or video file:" \
            --add-preview \
            --large-preview \
            --image-filter="*.png *.jpg *.jpeg *.webp *.svg *.gif *.mp4 *.MP4 *.mov *.MOV" \
            --window-icon="gtk-color-picker" \
            --center \
            --buttons-layout=end \
            --button="Select:0" \
            --button="Cancel:1" \
            2>/dev/null)
            
    # Try zenity
    elif command -v zenity >/dev/null 2>&1; then
        echo "Using zenity file picker..." >&2
        selected_file=$(zenity --file-selection \
            --title="Choose Wallpaper" \
            --filename="$(xdg-user-dir PICTURES)" \
            --file-filter="Image files | *.png *.jpg *.jpeg *.webp *.svg *.gif" \
            --file-filter="Video files | *.mp4 *.MP4 *.mov *.MOV" \
            --file-filter="All files | *" \
            2>/dev/null)
            
    # Fallback to command line
    else
        echo "No GUI file picker found. Using command line browser..." >&2
        selected_file=$(command_line_file_browser)
    fi
    
    # Restore original theme immediately after file selection
    restore_original_theme
    
    # Validate and return
    if [[ -n "$selected_file" && -f "$selected_file" ]]; then
        echo "$selected_file"
    else
        echo ""
    fi
}

command_line_file_browser() {
    local wallpaper_dir
    wallpaper_dir="$(xdg-user-dir PICTURES)"
    [[ ! -d "$wallpaper_dir" ]] && wallpaper_dir="$HOME"
    
    echo "Available files in $wallpaper_dir:"
    local files=()
    while IFS= read -r -d $'\0' file; do
        files+=("$file")
    done < <(find "$wallpaper_dir" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.gif" -o -name "*.mp4" -o -name "*.mov" \) -print0 2>/dev/null | head -z -20)
    
    for i in "${!files[@]}"; do
        printf "%2d: %s\n" $((i+1)) "$(basename "${files[i]}")"
    done
    
    echo -n "Enter file number or full path: "
    read -r selected_file
    
    # If user entered a number, convert it to filename
    if [[ "$selected_file" =~ ^[0-9]+$ ]] && [[ "$selected_file" -le "${#files[@]}" ]]; then
        echo "${files[$((selected_file-1))]}"
    else
        echo "$selected_file"
    fi
}

get_cursor_pos() {
    # For Hyprland on GNOME, use hyprctl to get cursor position
    if is_hyprland && command -v hyprctl >/dev/null 2>&1; then
        local scale screenx screeny screensizey
        read -r scale screenx screeny screensizey < <(
            hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.scale) \(.x) \(.y) \(.height)"' 2>/dev/null || echo "1 0 0 1080"
        )

        cursorposx=$(hyprctl cursorpos -j | jq -r '.x' 2>/dev/null || echo 960)
        cursorposx=$(bc <<<"scale=0; ($cursorposx - $screenx) * $scale / 1" 2>/dev/null || echo 960)

        cursorposy=$(hyprctl cursorpos -j | jq -r '.y' 2>/dev/null || echo 540)
        cursorposy=$(bc <<<"scale=0; ($cursorposy - $screeny) * $scale / 1" 2>/dev/null || echo 540)

        cursorposy_inverted=$((screensizey - cursorposy))
    else
        # Fallback values if Hyprland is not running
        cursorposx=960
        cursorposy_inverted=540
    fi
}

# ------------ Template Processing ------------
replace_colors_in_template() {
    local template="$1"
    local output="$2"

    cp "$template" "$output"

    for i in "${!colorlist[@]}"; do
        local color_name="${colorlist[$i]}"
        local color_value="${colorvalues[$i]}"

        sed -i \
            -e "s/#{{ ${color_name} }}/#${color_value}/g" \
            -e "s/@{{ ${color_name} }}/@${color_value}/g" \
            -e "s/{{ ${color_name} }}/${color_value}/g" \
            "$output"
    done
}

resolve_color_references() {
    local file="$1"
    local processed_file
    processed_file=$(cat "$file")

    while IFS= read -r line; do
        if [[ $line =~ @define-color[[:space:]]+([^[:space:]]+)[[:space:]]+@([^[:space:]]+) ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local ref_var="${BASH_REMATCH[2]}"
            local ref_value
            ref_value=$(echo "$processed_file" | grep -oP "@define-color\s+${ref_var}\s+\K[^;]+")

            if [[ -n "$ref_value" ]]; then
                sed -i "s|@define-color[[:space:]]\+${var_name}[[:space:]]\+@${ref_var}|@define-color ${var_name} ${ref_value}|g" "$file"
            fi
        fi
    done < "$file"
}

# ------------ Application-specific Theming ------------
apply_hyprland() {
    local template="$CONFIG_DIR/scripts/templates/hypr/themes/colors.conf"
    local output="$CACHE_DIR/user/generated/hypr/colors.conf"

    if [[ ! -f "$template" ]]; then
        echo "Warning: Hyprland template not found. Creating basic colors.conf..." >&2
        create_basic_hyprland_colors
        return 0
    fi

    cp "$template" "$output"

    for i in "${!colorlist[@]}"; do
        local color_name="${colorlist[$i]#$}"
        local color_value="${colorvalues[$i]#\#}"

        sed -i \
            -e "s/{{ ${color_name} }}/${color_value}/g" \
            -e "s/rgba({{ ${color_name} }}ff)/rgba(${color_value}ff)/g" \
            -e "s/rgba({{ ${color_name} }}cc)/rgba(${color_value}cc)/g" \
            "$output"
    done

    mkdir -p "$XDG_CONFIG_HOME/hypr/themes"
    cp "$output" "$XDG_CONFIG_HOME/hypr/themes/colors.conf"
    
    # Reload Hyprland if running
    if is_hyprland && command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload 2>/dev/null || true
        echo "Reloaded Hyprland with new colors" >&2
    fi
}

create_basic_hyprland_colors() {
    mkdir -p "$XDG_CONFIG_HOME/hypr/themes"
    cat > "$XDG_CONFIG_HOME/hypr/themes/colors.conf" << EOF
# Basic Hyprland colors generated by theme engine
# Using WhiteSur-Dark-solid-alt-red-nord as base

# Wallpaper colors
\$wallpaper-primary = ${colorvalues[4]}
\$wallpaper-accent = ${colorvalues[1]}
\$wallpaper-background = ${colorvalues[0]}

# Application colors
\$color0 = ${colorvalues[0]}
\$color1 = ${colorvalues[1]}  
\$color2 = ${colorvalues[2]}
\$color3 = ${colorvalues[3]}
\$color4 = ${colorvalues[4]}
\$color5 = ${colorvalues[5]}
\$color6 = ${colorvalues[6]}
\$color7 = ${colorvalues[7]}

# Hyprland specific - WhiteSur compatible
\$active_border = \$color4
\$inactive_border = \$color0
EOF
}

apply_gtk() {
    local template="$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css"
    local output="$CACHE_DIR/user/generated/gtk/gtk-colors.css"

    configure_gtk_theme
    configure_flatpak_theme

    # Only apply custom colors if template exists
    if [[ -f "$template" ]]; then
        replace_colors_in_template "$template" "$output"
        resolve_color_references "$output"

        mkdir -p "$XDG_CONFIG_HOME/gtk-3.0" "$XDG_CONFIG_HOME/gtk-4.0"

        # Add custom colors without breaking theme
        cp "$output" "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
        cp "$output" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"
        echo "Applied custom GTK colors" >&2
    else
        # Remove custom gtk.css to use pure WhiteSur theme
        rm -f "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
        rm -f "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"
        echo "Using pure WhiteSur theme without custom colors" >&2
    fi

    # Update icon cache
    gtk-update-icon-cache -f -t ~/.local/share/icons/WhiteSur-dark 2>/dev/null || true
    
    # Restart GNOME Shell if running under GNOME
    if is_gnome && command -v gnome-shell >/dev/null 2>&1; then
        busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting GNOME Shell for theme changes")' 2>/dev/null || true
        echo "Restarted GNOME Shell for theme changes" >&2
    fi
}

configure_gtk_theme() {
    # Always use WhiteSur theme as default
    local selected_theme="$DEFAULT_GTK_THEME"
    
    # Use dconf for permanent systemwide theming
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/gnome/desktop/interface/gtk-theme "'$selected_theme'" 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
        echo "Applied permanent dark theme via dconf: $selected_theme" >&2
    fi
    
    # Also set via gsettings for compatibility
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme "$selected_theme" 2>/dev/null || true
        echo "Applied theme via gsettings: $selected_theme" >&2
    fi

    # Export for use in configure_flatpak_theme
    export SELECTED_GTK_THEME="$selected_theme"
}

configure_flatpak_theme() {
    command -v flatpak >/dev/null 2>&1 || return 0

    local theme="${SELECTED_GTK_THEME:-$DEFAULT_GTK_THEME}"

    # Set global Flatpak permissions for WhiteSur compatibility
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
    flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
    flatpak override --user --filesystem=~/.themes:ro 2>/dev/null || true
    flatpak override --user --filesystem=~/.local/share/themes:ro 2>/dev/null || true
    flatpak override --user --env=GTK_THEME="$theme" 2>/dev/null || true
    flatpak override --user --env=XDG_CURRENT_DESKTOP=GNOME 2>/dev/null || true

    # Apply to individual apps
    flatpak list --app --columns=application 2>/dev/null | while read -r app; do
        [[ -n "$app" ]] || continue
        flatpak override --user "$app" --env=GTK_THEME="$theme" 2>/dev/null || true
        flatpak override --user "$app" --env=XDG_CURRENT_DESKTOP=GNOME 2>/dev/null || true
    done
    
    echo "Applied WhiteSur theme to Flatpak applications" >&2
}

apply_swaync() {
    local template="$CONFIG_DIR/scripts/templates/swaync/style.css"
    local output="$CACHE_DIR/user/generated/swaync/style.css"

    if [[ ! -f "$template" ]]; then
        echo "Warning: SwayNC template not found. Skipping notification center." >&2
        return 0
    fi

    mkdir -p "$CACHE_DIR/user/generated/swaync" "$XDG_CONFIG_HOME/swaync"

    cp "$template" "$output"

    for i in "${!colorlist[@]}"; do
        local color_name="${colorlist[$i]}"
        local color_value="${colorvalues[$i]}"
        sed -i -E "s/\{\{[[:space:]]*${color_name}[[:space:]]*\}\}/#${color_value}/g" "$output"
    done

    cp "$output" "$XDG_CONFIG_HOME/swaync/style.css"

    # Reload SwayNC if running
    if pgrep -x "swaync" >/dev/null; then
        pkill -USR2 swaync
        echo "Reloaded SwayNC with new colors" >&2
    fi
}

# ------------ Wallpaper & Color Generation ------------
set_wallpaper() {
    local imgpath="$1"

    if [[ "$imgpath" == *.mp4 ]] || [[ "$imgpath" == *.MP4 ]] || [[ "$imgpath" == *.mov ]] || [[ "$imgpath" == *.MOV ]]; then
        echo "Setting video wallpaper: $imgpath"
        pkill -f mpvpaper 2>/dev/null || true
        mpvpaper -o "no-audio loop" "*" "$imgpath" &

        if command -v magick >/dev/null 2>&1; then
            magick "${imgpath}[0]" -strip -quality 95 "$CACHE_DIR/video_frame.png" 2>/dev/null && \
                imgpath="$CACHE_DIR/video_frame.png"
            echo "Extracted video frame for color generation"
        fi
    else
        # Use swww for Hyprland or gsettings for GNOME
        if is_hyprland && command -v swww >/dev/null 2>&1; then
            get_cursor_pos
            swww img "$imgpath" \
                --transition-step 100 \
                --transition-fps 120 \
                --transition-type grow \
                --transition-angle 30 \
                --transition-duration 1 \
                --transition-pos "$cursorposx, $cursorposy_inverted" 2>/dev/null || true
            echo "Set Hyprland wallpaper: $imgpath" >&2
        elif is_gnome && command -v gsettings >/dev/null 2>&1; then
            # Set wallpaper for GNOME
            gsettings set org.gnome.desktop.background picture-uri "file://$imgpath" 2>/dev/null || true
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$imgpath" 2>/dev/null || true
            echo "Set GNOME wallpaper: $imgpath" >&2
        fi

        rm -f "$CACHE_DIR/video_frame.png"
    fi

    echo "$imgpath"
}

generate_colors() {
    local imgpath="$1"

    echo "Generating colors from wallpaper..." >&2
    
    # Generate colors using wal
    if command -v wal >/dev/null 2>&1; then
        wal -i "$imgpath" 2>/dev/null || true
        echo "Generated colors with pywal" >&2
    fi
    
    # Generate material colors if matugen is available
    if command -v matugen >/dev/null 2>&1; then
        /usr/bin/matugen image "$imgpath" 2>/dev/null || true
        echo "Generated material colors with matugen" >&2
    fi
    
    # Copy to rofi background if directory exists
    mkdir -p "$XDG_CONFIG_HOME/rofi/images"
    cp "$imgpath" "$XDG_CONFIG_HOME/rofi/images/background.png" 2>/dev/null || true

    sleep 1

    local wal_colors="$HOME/.cache/wal/colors.scss"
    if [[ ! -f "$wal_colors" ]]; then
        echo "Warning: wal colors.scss not found, using WhiteSur fallback colors" >&2
        create_whitesur_fallback_colors
    else
        extract_wal_colors "$wal_colors"
        generate_material_colors
        load_color_variables
        echo "Loaded generated colors successfully" >&2
    fi
}

create_whitesur_fallback_colors() {
    # WhiteSur dark nord red fallback colors
    background="242424"
    foreground="e5e9f0"
    cursor="bf616a"
    
    # WhiteSur nord red color scheme
    color[0]="2e3440"  # black
    color[1]="bf616a"  # red (nord red)
    color[2]="a3be8c"  # green
    color[3]="ebcb8b"  # yellow
    color[4]="81a1c1"  # blue
    color[5]="b48ead"  # magenta
    color[6]="88c0d0"  # cyan
    color[7]="e5e9f0"  # white
    color[8]="4c566a"  # bright black
    color[9]="bf616a"  # bright red
    color[10]="a3be8c" # bright green
    color[11]="ebcb8b" # bright yellow
    color[12]="81a1c1" # bright blue
    color[13]="b48ead" # bright magenta
    color[14]="8fbcbb" # bright cyan
    color[15]="eceff4" # bright white
    
    generate_material_colors
    load_color_variables
}

extract_wal_colors() {
    local wal_file="$1"

    background=$(grep '^\$background:' "$wal_file" | cut -d' ' -f2 | tr -d ';' || echo "242424")
    foreground=$(grep '^\$foreground:' "$wal_file" | cut -d' ' -f2 | tr -d ';' || echo "e5e9f0")
    cursor=$(grep '^\$cursor:' "$wal_file" | cut -d' ' -f2 | tr -d ';' || echo "bf616a")

    for i in {0..15}; do
        color[$i]=$(grep "^\$color${i}:" "$wal_file" | cut -d' ' -f2 | tr -d ';' || echo "2e3440")
    done
}

generate_material_colors() {
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
\$accent: ${color[1]};  # Using nord red as accent
EOF
}

load_color_variables() {
    colorlist=()
    colorvalues=()

    while IFS= read -r line; do
        local name value
        name=$(echo "$line" | awk -F':' '{gsub(/\$/,"",$1); gsub(/ /,"",$1); print substr($1,2)}')
        value=$(echo "$line" | awk -F':' '{gsub(/;/,"",$2); gsub(/ /,"",$2); print $2}')

        if [[ -n "$name" && -n "$value" ]]; then
            colorlist+=("$name")
            colorvalues+=("$value")
        fi
    done < "$STATE_DIR/scss/_material.scss"
}

generate_wallpaper_variants() {
    local imgpath="$1"

    if ! command -v magick >/dev/null 2>&1; then
        echo "ImageMagick not available, skipping wallpaper variants" >&2
        return 0
    fi

    echo "Generating wallpaper variants..." >&2
    
    # Generate various wallpaper variants in parallel
    magick "${imgpath}[0]" -strip -resize 1000 -gravity center -extent 1000 -quality 90 \
        "$CACHE_DIR/wall.thmb" 2>/dev/null &

    magick "${imgpath}[0]" -strip -distort SRT '1.8 0' -thumbnail 500x500^ -gravity center -extent 500x500 \
        "$CACHE_DIR/wall.sqre" 2>/dev/null &

    magick "${imgpath}[0]" -strip -scale 10% -blur 0x3 -resize 100% \
        "$CACHE_DIR/wall.blur" 2>/dev/null &

    if [[ "${imgpath}" != *.png ]] || [[ "${imgpath}" == "$CACHE_DIR/video_frame.png" ]]; then
        magick "${imgpath}[0]" -strip -quality 95 "$CACHE_DIR/wall.png" 2>/dev/null &
    fi
    
    wait
    echo "Wallpaper variants generated" >&2
}

# ------------ Main Functions ------------
switch_theme() {
    local imgpath="$1"

    if [[ -z "$imgpath" ]]; then
        echo 'Aborted: No wallpaper path provided' >&2
        exit 0
    fi
    
    if [[ ! -f "$imgpath" ]]; then
        echo "Error: File not found: $imgpath" >&2
        exit 1
    fi

    echo "Switching theme using: $imgpath" >&2
    echo "Using WhiteSur-Dark-solid-alt-red-nord as GTK theme" >&2
    
    imgpath=$(set_wallpaper "$imgpath")
    generate_colors "$imgpath"
    generate_wallpaper_variants "$imgpath"

    # Apply themes in parallel
    apply_hyprland &
    apply_swaync &
    apply_gtk &
    wait

    echo "Theme switching complete! WhiteSur theme applied successfully." >&2
}

main() {
    # Set up error handling to ensure theme is restored
    trap restore_original_theme EXIT INT TERM
    
    init_directories

    if [[ -n "${1:-}" ]]; then
        switch_theme "$1"
    else
        local wallpaper_dir
        wallpaper_dir="$(xdg-user-dir HOME)/Nextcloud/Wallpapers"
        if [[ ! -d "$wallpaper_dir" ]]; then
            wallpaper_dir="$(xdg-user-dir PICTURES)"
        fi
        if [[ ! -d "$wallpaper_dir" ]]; then
            wallpaper_dir="$HOME"
        fi

        if cd "$wallpaper_dir" 2>/dev/null; then
            local selected_wallpaper
            selected_wallpaper="$(open_file_picker)"
            
            if [[ -n "$selected_wallpaper" && -f "$selected_wallpaper" ]]; then
                switch_theme "$selected_wallpaper"
            else
                echo "No wallpaper selected or file not found: $selected_wallpaper" >&2
                exit 1
            fi
        else
            echo "Error: Cannot access wallpaper directory: $wallpaper_dir" >&2
            exit 1
        fi
    fi
}

main "$@"