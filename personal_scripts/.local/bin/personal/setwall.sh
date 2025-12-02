#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

# Default cache directory
CACHE_DIR="${CACHE_DIR:-$HOME/.cache/wallpaper}"

# Helper functions
is_hyprland() {
  [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]] || pgrep -x Hyprland >/dev/null
}

is_gnome() {
  [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]
}

is_kde() {
  [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || pgrep -x plasmashell >/dev/null
}

get_cursor_pos() {
  if command -v hyprctl >/dev/null 2>&1; then
    local pos=$(hyprctl cursorpos 2>/dev/null)
    cursorposx=$(echo "$pos" | cut -d',' -f1)
    cursorposy=$(echo "$pos" | cut -d',' -f2)
    cursorposy_inverted=$((1080 - cursorposy)) # Adjust for your resolution
  else
    cursorposx=960
    cursorposy_inverted=540
  fi
}

# Initialize directories
init_directories() {
  mkdir -p "$CACHE_DIR"
}

# Validate image/video file
validate_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file" >&2
    return 1
  fi
  if [[ ! -r "$file" ]]; then
    echo "Error: File not readable: $file" >&2
    return 1
  fi
  return 0
}

set_video_wallpaper() {
  local videopath="$1"
  validate_file "$videopath" || return 1

  echo "Setting video wallpaper: $videopath" >&2
  pkill -f mpvpaper 2>/dev/null
  sleep 0.2
  mpvpaper -o "no-audio loop" "*" "$videopath" >/dev/null 2>&1 &
  echo "Video wallpaper set: $videopath" >&2

  # Return the final wallpaper path
  echo "$videopath"
}

generate_wallpaper_variants() {
  local imgpath="$1"

  if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick not available, skipping wallpaper variants" >&2
    return 0
  fi

  validate_file "$imgpath" || return 1

  echo "Generating wallpaper variants..." >&2

  {
    magick "${imgpath}[0]" -strip -resize 1000 -gravity center -extent 1000 -quality 90 \
      "$CACHE_DIR/wall.thmb" 2>/dev/null
  } &

  {
    magick "${imgpath}[0]" -strip -distort SRT '1.8 0' -thumbnail 500x500^ -gravity center -extent 500x500 \
      "$CACHE_DIR/wall.sqre" 2>/dev/null
  } &

  {
    magick "${imgpath}[0]" -strip -scale 10% -blur 0x3 -resize 100% \
      "$CACHE_DIR/wall.blur" 2>/dev/null
  } &

  # Full-size PNG
  if [[ "$imgpath" != *.png ]]; then
    {
      magick "${imgpath}[0]" -strip -quality 95 "$CACHE_DIR/wall.png" 2>/dev/null
    } &
  fi

  wait
  echo "Wallpaper variants generated" >&2
}

generate_material_colors() {
  local imgpath="$1"

  if ! command -v matugen >/dev/null 2>&1; then
    return 0
  fi

  validate_file "$imgpath" || return 1

  echo "Generating material colors..." >&2
  if /usr/bin/matugen image "$imgpath" 2>/dev/null; then
    echo "Generated material colors with matugen" >&2
  else
    echo "Warning: matugen failed to generate colors" >&2
  fi
}

set_wallpaper() {
  local imgpath="$1"
  validate_file "$imgpath" || return 1

  # Handle video wallpapers separately
  if [[ "$imgpath" =~ \.(mp4|MP4|mov|MOV|webm|WEBM)$ ]]; then
    set_video_wallpaper "$imgpath"
    return
  fi

  # Handle image wallpapers based on desktop environment
  if is_hyprland && command -v swww >/dev/null 2>&1; then
    get_cursor_pos
    if swww img "$imgpath" \
      --transition-step 100 \
      --transition-fps 120 \
      --transition-type grow \
      --transition-angle 30 \
      --transition-duration 1 \
      --transition-pos "$cursorposx,$cursorposy_inverted" 2>/dev/null; then
      echo "Set Hyprland wallpaper: $imgpath" >&2
    else
      echo "Warning: swww failed, wallpaper may not be set" >&2
    fi

    # Only generate variants and colors for Hyprland
    generate_wallpaper_variants "$imgpath"
    generate_material_colors "$imgpath"

    # Copy to rofi background (Hyprland only)
    local rofi_images_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/images"
    mkdir -p "$rofi_images_dir" 2>/dev/null
    if cp "$imgpath" "$rofi_images_dir/background.png" 2>/dev/null; then
      echo "Copied wallpaper to rofi background" >&2
    else
      echo "Warning: Could not copy wallpaper to rofi directory" >&2
    fi

  elif is_gnome && command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.background picture-uri "file://$imgpath" 2>/dev/null
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$imgpath" 2>/dev/null
    echo "Set GNOME wallpaper: $imgpath" >&2
    generate_material_colors "$imgpath"

  elif is_kde && command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    plasma-apply-wallpaperimage "$imgpath" 2>/dev/null
    echo "Set KDE Plasma wallpaper: $imgpath" >&2
    # Skip variants and color generation for KDE
  else
    echo "Warning: No supported desktop environment detected" >&2
  fi

  # Return the final wallpaper path
  echo "$imgpath"
}

# Open file picker to select wallpaper
open_file_picker() {
  if command -v yad >/dev/null 2>&1; then
    yad --file --title="Select Wallpaper" \
      --file-filter="Images|*.jpg *.jpeg *.png *.gif *.bmp *.webp" \
      --file-filter="Videos|*.mp4 *.mov *.webm" \
      --file-filter="All files|*" \
      --width=1200 \
      --height=800 \
      --add-preview \
      --large-preview \
      --center \
      --buttons-layout=end \
      --button="Select:0" \
      --button="Cancel:1"
  elif command -v zenity >/dev/null 2>&1; then
    zenity --file-selection --title="Select Wallpaper" \
      --file-filter="Images (jpg,png,gif,webp) | *.jpg *.jpeg *.png *.gif *.bmp *.webp" \
      --file-filter="Videos (mp4,mov,webm) | *.mp4 *.mov *.webm" \
      --file-filter="All files | *"
  elif command -v kdialog >/dev/null 2>&1; then
    kdialog --getopenfilename . "*.jpg *.jpeg *.png *.gif *.bmp *.webp *.mp4 *.mov *.webm|Media Files"
  else
    echo "Error: No file picker found (yad, zenity, or kdialog required)" >&2
    return 1
  fi
}

# Main function
main() {
  init_directories

  if [[ -n "${1:-}" ]]; then
    # Wallpaper path provided as argument
    set_wallpaper "$1"
  else
    # No argument - open file picker
    local wallpaper_dir
    wallpaper_dir="$(xdg-user-dir PICTURES)"
    if [[ ! -d "$wallpaper_dir" ]]; then
      wallpaper_dir="$HOME/Pictures"
    fi
    if [[ ! -d "$wallpaper_dir" ]]; then
      wallpaper_dir="$HOME"
    fi

    if cd "$wallpaper_dir" 2>/dev/null; then
      local selected_wallpaper
      selected_wallpaper="$(open_file_picker)"

      if [[ -n "$selected_wallpaper" && -f "$selected_wallpaper" ]]; then
        set_wallpaper "$selected_wallpaper"
      else
        echo "No wallpaper selected or file not found" >&2
        exit 1
      fi
    else
      echo "Error: Cannot access wallpaper directory: $wallpaper_dir" >&2
      exit 1
    fi
  fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
