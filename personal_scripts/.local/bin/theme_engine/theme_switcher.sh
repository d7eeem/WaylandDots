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
  cursorposx=$(bc <<<"scale=0; ($cursorposx - $screenx) * $scale / 1")
  cursorposy=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null) || cursorposy=540
  cursorposy=$(bc <<<"scale=0; ($cursorposy - $screeny) * $scale / 1")
  cursorposy_inverted=$((screensizey - cursorposy))
}

apply_hyprland() {
  if [ ! -f "$CONFIG_DIR/scripts/templates/hypr/themes/colors.conf" ]; then
    echo "Template file not found for Hyprland colors. Skipping that."
    return
  fi

  # Copy template
  cp "$CONFIG_DIR/scripts/templates/hypr/themes/colors.conf" "$CACHE_DIR/user/generated/hypr/colors.conf"

  # Replace color variables
  for i in "${!colorlist[@]}"; do
    color_name=${colorlist[$i]#$}
    color_value=${colorvalues[$i]#\#}

    sed -i "s/{{ ${color_name} }}/${color_value}/g" "$CACHE_DIR/user/generated/hypr/colors.conf"

    sed -i "s/rgba({{ ${color_name} }}ff)/rgba(${color_value}ff)/g" "$CACHE_DIR/user/generated/hypr/colors.conf"
    sed -i "s/rgba({{ ${color_name} }}cc)/rgba(${color_value}cc)/g" "$CACHE_DIR/user/generated/hypr/colors.conf"
  done

  cp "$CACHE_DIR/user/generated/hypr/colors.conf" "$XDG_CONFIG_HOME/hypr/themes/colors.conf"
}

apply_hyprlock() {
  if [ ! -f "$CONFIG_DIR/scripts/templates/hypr/hyprlock.conf" ]; then
    echo "Template file not found for hyprlock. Skipping that."
    return
  fi

  current_wall=$(swww query | head -1 | awk -F 'image: ' '{print $2}')

  cp "$CONFIG_DIR/scripts/templates/hypr/hyprlock.conf" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"

  sed -i "s|path = .*|path = $current_wall|" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
  for i in "${!colorlist[@]}"; do
    color_name=${colorlist[$i]#$}
    color_value=${colorvalues[$i]#\#}
    sed -i "s/#{{ ${color_name} }}/#${color_value}/g" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
    sed -i "s/{{ ${color_name} }}/${color_value}/g" "$CACHE_DIR/user/generated/hypr/hyprlock.conf"
  done

  cp "$CACHE_DIR/user/generated/hypr/hyprlock.conf" "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
}

apply_gtk() {
  # Check if GNOME-macOS-Tahoe theme is installed and skip if it is
  if [ -d "/usr/share/themes/Tahoe-Dark" ] || [ -d "/usr/share/themes/Tahoe-Light" ] || [ -d "$HOME/.local/share/themes/Tahoe-Dark" ] || [ -d "$HOME/.local/share/themes/Tahoe-Light" ] || [ -d "$HOME/.themes/Tahoe-Dark" ] || [ -d "$HOME/.themes/Tahoe-Light" ]; then
    echo "GNOME-macOS-Tahoe theme detected. Skipping GTK color application to preserve theme integrity."
    return
  fi

  if [ ! -f "$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css" ]; then
    echo "Template file not found for gtk colors. Skipping that."
    return
  fi

  current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
  current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)

  cp "$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"

  for i in "${!colorlist[@]}"; do
    color_name=${colorlist[$i]#$}
    color_value=${colorvalues[$i]#\#}

    sed -i "s/#{{ ${color_name} }}/#${color_value}/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
    sed -i "s/@{{ ${color_name} }}/@${color_value}/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
    sed -i "s/{{ ${color_name} }}/${color_value}/g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
  done

  processed_file=$(cat "$CACHE_DIR/user/generated/gtk/gtk-colors.css")
  while IFS= read -r line; do
    if [[ $line =~ @define-color[[:space:]]+([^[:space:]]+)[[:space:]]+@([^[:space:]]+) ]]; then
      var_name="${BASH_REMATCH[1]}"
      ref_var="${BASH_REMATCH[2]}"
      ref_value=$(echo "$processed_file" | grep -oP "@define-color\s+${ref_var}\s+\K[^;]+")
      if [ ! -z "$ref_value" ]; then
        sed -i "s|@define-color[[:space:]]\+${var_name}[[:space:]]\+@${ref_var}|@define-color ${var_name} ${ref_value}|g" "$CACHE_DIR/user/generated/gtk/gtk-colors.css"
      fi
    fi
  done <"$CACHE_DIR/user/generated/gtk/gtk-colors.css"

  mkdir -p "$XDG_CONFIG_HOME/gtk-3.0"
  mkdir -p "$XDG_CONFIG_HOME/gtk-4.0"

  cp "$CACHE_DIR/user/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
  cp "$CACHE_DIR/user/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"

  gsettings set org.gnome.desktop.interface gtk-theme ''

  if [[ "$current_theme" == *"dark"* ]] || [[ "$current_scheme" == *"prefer-dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Tahoe-Dark'
    #gsettings set org.gnome.desktop.interface gtk-theme 'Everforest-Dark'
  else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    #gsettings set org.gnome.desktop.interface gtk-theme 'Everforest-Dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Tahoe-Dark'
  fi

  # Force GTK to reload the theme
  gtk-update-icon-cache -f -t ~/.local/share/icons/default 2>/dev/null || true
}
apply_swaync() {
  if [ ! -f "$CONFIG_DIR/scripts/templates/swaync/style.css" ]; then
    echo "Template file not found for swaync. Skipping that."
    return
  fi

  # Create necessary directories
  mkdir -p "$CACHE_DIR/user/generated/swaync"
  mkdir -p "$XDG_CONFIG_HOME/swaync"

  cp "$CONFIG_DIR/scripts/templates/swaync/style.css" "$CACHE_DIR/user/generated/swaync/style.css"

  for i in "${!colorlist[@]}"; do
    color_name=${colorlist[$i]#$}
    color_value=${colorvalues[$i]#\#}

    sed -i "s/@define-color ${color_name} .*/@define-color ${color_name} #${color_value}/g" "$CACHE_DIR/user/generated/swaync/style.css"
  done

  cp "$CACHE_DIR/user/generated/swaync/style.css" "$XDG_CONFIG_HOME/swaync/style.css"

  if pgrep -x "swaync" >/dev/null; then
    pkill -USR2 swaync
  fi
}

switch() {
  imgpath=$1

  if [ "$imgpath" == '' ]; then
    echo 'Aborted'
    exit 0
  fi

  get_cursor_pos

  swww img "$imgpath" --transition-step 100 --transition-fps 120 \
    --transition-type grow --transition-angle 30 --transition-duration 1 \
    --transition-pos "$cursorposx, $cursorposy_inverted"

  wal -i "$imgpath"
  /usr/bin/matugen image "$imgpath"
  cp "$imgpath" "$HOME/.config/rofi/images/background.png"

  sleep 0.5

  if [ -f "$HOME/.cache/wal/colors.scss" ]; then
    background=$(grep '^\$background:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
    foreground=$(grep '^\$foreground:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
    cursor=$(grep '^\$cursor:' "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')

    for i in {0..15}; do
      color[$i]=$(grep "^\$color${i}:" "$HOME/.cache/wal/colors.scss" | cut -d' ' -f2 | tr -d ';')
    done

    cat >"$STATE_DIR/scss/_material.scss" <<EOF
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

  colornames=$(cat "$STATE_DIR/scss/_material.scss" | cut -d: -f1)
  colorstrings=$(cat "$STATE_DIR/scss/_material.scss" | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
  IFS=$'\n'
  colorlist=("$colornames")
  colorvalues=("$colorstrings")

  apply_cache() {
    magick "${imgpath}[0]" -strip -resize 1000 -gravity center -extent 1000 -quality 90 "/home/tinker/.cache/theme_engine/wall.thmb"
    magick "${imgpath}[0]" -strip -thumbnail 500x500^ -gravity center -extent 500x500 "/home/tinker/.cache/theme_engine/wall.sqre"
    magick "${imgpath}[0]" -strip -scale 10% -blur 0x3 -resize 100% "/home/tinker/.cache/theme_engine/wall.blur"
  }

  apply_hyprland &
  apply_hyprlock &
  apply_swaync &
  apply_cache &
  apply_gtk &
  # apply_flatpak &
}

if [[ "$1" ]]; then
  switch "$1"
else
  cd "$(xdg-user-dir HOME)/Nextcloud/Wallpapers" || cd "$(xdg-user-dir PICTURES)" || exit 1
  switch "$(open_file_picker)"
fi
