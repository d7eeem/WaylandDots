#!/usr/bin/env bash
set -e
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR"
CACHE_DIR="$XDG_CACHE_HOME/theme_engine"
STATE_DIR="$XDG_STATE_HOME/theme_engine"

# Create necessary directories
mkdir -p "$CACHE_DIR/user/generated/{hypr,gtk}"
mkdir -p "$STATE_DIR/scss"

# Function to check if running under KDE
is_kde() {
  [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]
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
  local template="$CONFIG_DIR/scripts/templates/hypr/themes/colors.conf"
  local out="$CACHE_DIR/user/generated/hypr/colors.conf"
  [ -f "$template" ] || { echo "Template file not found for Hyprland colors. Skipping."; return; }
  cp "$template" "$out"
  for i in "${!colorlist[@]}"; do
    color_name=${colorlist[$i]}
    color_value=${colorvalues[$i]}
    sed -i "s/{{ ${color_name} }}/${color_value}/g" "$out"
    sed -i "s/rgba({{ ${color_name} }}ff)/rgba(${color_value}ff)/g" "$out"
    sed -i "s/rgba({{ ${color_name} }}cc)/rgba(${color_value}cc)/g" "$out"
  done
  cp "$out" "$XDG_CONFIG_HOME/hypr/themes/colors.conf"
}

apply_hyprlock() {
  local template="$CONFIG_DIR/scripts/templates/hypr/hyprlock.conf"
  local out="$CACHE_DIR/user/generated/hypr/hyprlock.conf"
  [ -f "$template" ] || { echo "Template file not found for hyprlock. Skipping."; return; }
  current_wall=$(swww query | head -1 | awk -F 'image: ' '{print $2}')
  if [ -f "$CACHE_DIR/video_frame.png" ]; then
    hyprlock_wall="$CACHE_DIR/video_frame.png"
  elif [[ "$current_wall" == *.png ]]; then
    hyprlock_wall="$current_wall"
  else
    hyprlock_wall="$CACHE_DIR/wall.png"
  fi
  cp "$template" "$out"
  sed -i "s|path = .*|path = $hyprlock_wall|" "$out"
  for i in "${!colorlist[@]}"; do
    color_name=${colorlist[$i]}
    color_value=${colorvalues[$i]}
    sed -i "s/#{{ ${color_name} }}/#${color_value}/g" "$out"
    sed -i "s/{{ ${color_name} }}/${color_value}/g" "$out"
  done
  cp "$out" "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
}

apply_gtk() {
  if [ -d "/usr/share/themes/Tahoe-Dark" ] || [ -d "/usr/share/themes/Tahoe-Light" ] || [ -d "$HOME/.local/share/themes/Tahoe-Dark" ] || [ -d "$HOME/.local/share/themes/Tahoe-Light" ] || [ -d "$HOME/.themes/Tahoe-Dark" ] || [ -d "$HOME/.themes/Tahoe-Light" ]; then
    echo "GNOME-macOS-Tahoe theme detected. Skipping GTK color application to preserve theme integrity."
    return
  fi
  local template="$CONFIG_DIR/scripts/templates/gtk/gtk-colors.css"
  local out="$CACHE_DIR/user/generated/gtk/gtk-colors.css"
  [ -f "$template" ] || { echo "Template file not found for gtk colors. Skipping."; return; }
  current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
  current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
  cp "$template" "$out"
  for i in "${!colorlist[@]}"; do
    color_name=${colorlist[$i]}
    color_value=${colorvalues[$i]}
    sed -i "s/#{{ ${color_name} }}/#${color_value}/g" "$out"
    sed -i "s/@{{ ${color_name} }}/@${color_value}/g" "$out"
    sed -i "s/{{ ${color_name} }}/${color_value}/g" "$out"
  done
  processed_file=$(cat "$out")
  while IFS= read -r line; do
    if [[ $line =~ @define-color[[:space:]]+([^[:space:]]+)[[:space:]]+@([^[:space:]]+) ]]; then
      var_name="${BASH_REMATCH[1]}"
      ref_var="${BASH_REMATCH[2]}"
      ref_value=$(echo "$processed_file" | grep -oP "@define-color\s+${ref_var}\s+\K[^;]+")
      if [ ! -z "$ref_value" ]; then
        sed -i "s|@define-color[[:space:]]\+${var_name}[[:space:]]\+@${ref_var}|@define-color ${var_name} ${ref_value}|g" "$out"
      fi
    fi
  done <"$out"
  mkdir -p "$XDG_CONFIG_HOME/gtk-3.0" "$XDG_CONFIG_HOME/gtk-4.0"
  cp "$out" "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
  cp "$out" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"
  gsettings set org.gnome.desktop.interface gtk-theme ''
  if [[ "$current_theme" == *"dark"* ]] || [[ "$current_scheme" == *"prefer-dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Tahoe-Dark'
  else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme 'Tahoe-Dark'
  fi
  gtk-update-icon-cache -f -t ~/.local/share/icons/default 2>/dev/null || true
}

apply_swaync() {
  local template="$CONFIG_DIR/scripts/templates/swaync/style.css"
  local out="$CACHE_DIR/user/generated/swaync/style.css"
  [ -f "$template" ] || { echo "Template file not found for swaync. Skipping."; return; }
  mkdir -p "$CACHE_DIR/user/generated/swaync" "$XDG_CONFIG_HOME/swaync"
  cp "$template" "$out"
  for i in "${!colorlist[@]}"; do
    color_name=${colorlist[$i]}
    color_value=${colorvalues[$i]}
    sed -i -E "s/\{\{[[:space:]]*${color_name}[[:space:]]*\}\}/#${color_value}/g" "$out"
  done
  cp "$out" "$XDG_CONFIG_HOME/swaync/style.css"
  if pgrep -x "swaync" >/dev/null; then
    pkill -USR2 swaync
  fi
}

switch() {
  imgpath=$1
  [ "$imgpath" == '' ] && { echo 'Aborted'; exit 0; }
  get_cursor_pos
  if [[ "$imgpath" == *.mp4 ]] || [[ "$imgpath" == *.MP4 ]]; then
    echo "Detected MP4 video wallpaper: $imgpath"
    pkill -f mpvpaper 2>/dev/null || true
    mpvpaper -o "no-audio loop" "*" "$imgpath" &
    magick "${imgpath[0]}" -strip -quality 95 "$CACHE_DIR/video_frame.png"
    imgpath="$CACHE_DIR/video_frame.png"
    echo "Extracted frame from video for color generation: $imgpath"
  else
    swww img "$imgpath" --transition-step 100 --transition-fps 120 \
      --transition-type grow --transition-angle 30 --transition-duration 1 \
      --transition-pos "$cursorposx, $cursorposy_inverted"
    # Remove old video frame if it exists
    [ -f "$CACHE_DIR/video_frame.png" ] && rm "$CACHE_DIR/video_frame.png"
  fi
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
$rosewater: ${color[6]};
$flamingo: ${color[7]};
$pink: ${color[5]};
$mauve: ${color[4]};
$red: ${color[1]};
$maroon: ${color[2]};
$peach: ${color[3]};
$yellow: ${color[3]};
$green: ${color[2]};
$teal: ${color[4]};
$sky: ${color[4]};
$sapphire: ${color[4]};
$blue: ${color[4]};
$lavender: ${color[5]};
$text: ${foreground};
$subtext1: ${foreground};
$subtext0: ${foreground};
$overlay2: ${foreground};
$overlay1: ${foreground};
$overlay0: ${foreground};
$surface2: ${background};
$surface1: ${background};
$surface0: ${background};
$base: ${background};
$mantle: ${background};
$crust: ${background};
$accent: ${color[4]}; 
EOF
  else
    echo "Error: wal colors.scss not found"
    exit 1
  fi
  colorlist=()
  colorvalues=()
  while IFS= read -r line; do
    name=$(echo "$line" | awk -F':' '{gsub(/\$/,"",$1); gsub(/ /,"",$1); print substr($1,2)}')
    value=$(echo "$line" | awk -F':' '{gsub(/;/,"",$2); gsub(/ /,"",$2); print $2}')
    if [[ -n "$name" && -n "$value" ]]; then
      colorlist+=("$name")
      colorvalues+=("$value")
    fi
  done < "$STATE_DIR/scss/_material.scss"
  magick "${imgpath}[0]" -strip -resize 1000 -gravity center -extent 1000 -quality 90 "$CACHE_DIR/wall.thmb" &
  magick "${imgpath}[0]" -strip -distort SRT '1.8 0' -thumbnail 500x500^ -gravity center -extent 500x500 "$CACHE_DIR/wall.sqre" &
  magick "${imgpath}[0]" -strip -scale 10% -blur 0x3 -resize 100% "$CACHE_DIR/wall.blur" &
  if [[ "${imgpath}" != *.png ]]; then
    magick "${imgpath}[0]" -strip -quality 95 "$CACHE_DIR/wall.png"
  fi
  if [[ "${imgpath}" == "$CACHE_DIR/video_frame.png" ]]; then
    cp "$CACHE_DIR/video_frame.png" "$CACHE_DIR/wall.png"
  fi
  apply_hyprland &
  apply_swaync &
  apply_gtk &
  wait
  apply_hyprlock &
}

if [[ "$1" ]]; then
  switch "$1"
else
  cd "$(xdg-user-dir HOME)/Nextcloud/Wallpapers" || cd "$(xdg-user-dir PICTURES)" || exit 1
  switch "$(open_file_picker)"
fi
