#!/usr/bin/env bash
# _    _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_ /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem
#
# Wallpaper Manager
# Set wallpapers across multiple desktop environments with material design theming

set -euo pipefail

# ============================================================================
# Configuration & Setup
# ============================================================================

readonly CACHE_DIR="${CACHE_DIR:-$HOME/.cache/wallpaper}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load thumbnail generator library
# NOTE: wallcacher.sh must contain the definition for generate_rofi_thumbnails
if ! source "$SCRIPT_DIR/wallcacher.sh" 2>/dev/null; then
  echo "Error: Cannot load wallcacher.sh" >&2
  echo "Please ensure it's in the same directory as this script: $SCRIPT_DIR" >&2
  exit 1
fi

# Ensure cache directory exists
initialize() {
  mkdir -p "$CACHE_DIR" 2>/dev/null || {
    echo "Error: Cannot create cache directory: $CACHE_DIR" >&2
    exit 1
  }
}

# ============================================================================
# Desktop Environment Detection
# ============================================================================

is_hyprland() {
  [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]] || pgrep -x Hyprland >/dev/null 2>&1
}

is_gnome() {
  [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]
}

is_kde() {
  [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || pgrep -x plasmashell >/dev/null 2>&1
}

# ============================================================================
# Utilities
# ============================================================================

get_hyprland_cursor_position() {
  if ! command -v hyprctl >/dev/null 2>&1; then
    # Fallback to center screen position (1920x1080 resolution assumption)
    echo "960,540"
    return
  fi

  local pos
  pos=$(hyprctl cursorpos 2>/dev/null || echo "960,540")

  local x y
  x=$(echo "$pos" | cut -d',' -f1)
  y=$(echo "$pos" | cut -d',' -f2)

  # Invert Y for transition (adjust 1080 to your screen height)
  local y_inverted=$((1080 - y))

  echo "$x,$y_inverted"
}

validate_media_file() {
  local filepath="$1"

  if [[ ! -f "$filepath" ]]; then
    echo "Error: File not found: $filepath" >&2
    return 1
  fi

  if [[ ! -r "$filepath" ]]; then
    echo "Error: File not readable: $filepath" >&2
    return 1
  fi

  return 0
}

is_video_file() {
  local filepath="$1"
  # Case-insensitive check for common video extensions
  [[ "$filepath" =~ \.(mp4|mov|webm)$ ]]
}

resolve_wallpaper_directory() {
  local -a search_paths=(
    "$HOME/Nextcloud/wallpaper"
    "$(xdg-user-dir PICTURES 2>/dev/null || echo "")"
    "$HOME/Pictures"
    "$HOME"
  )

  for dir in "${search_paths[@]}"; do
    if [[ -n "$dir" && -d "$dir" ]]; then
      echo "$dir"
      return 0
    fi
  done

  echo "Error: No valid wallpaper directory found" >&2
  return 1
}

# ============================================================================
# Video Wallpaper Handler
# ============================================================================

set_video_wallpaper() {
  local videopath="$1"

  validate_media_file "$videopath" || return 1

  if ! command -v mpvpaper >/dev/null 2>&1; then
    echo "Error: mpvpaper not installed - cannot set video wallpaper" >&2
    return 1
  fi

  echo "Setting video wallpaper: $videopath" >&2

  # Stop existing video wallpaper
  pkill -f mpvpaper 2>/dev/null || true
  sleep 0.2

  # Start new video wallpaper
  mpvpaper -o "no-audio loop" "*" "$videopath" >/dev/null 2>&1 &
  echo "Video wallpaper active: $videopath" >&2
  echo "$videopath"
}

# ============================================================================
# Wallpaper Variant & Color Generation (Dependencies: magick, matugen)
# ============================================================================

generate_wallpaper_variants() {
  local source_image="$1"

  if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick not available - skipping variant generation" >&2
    return 0
  fi

  validate_media_file "$source_image" || return 1

  echo "Generating wallpaper variants..." >&2

  # Create variants in parallel using command grouping
  {
    # 1. Thumbnail (1000x1000)
    magick "${source_image}[0]" \
      -strip \
      -resize 1000 \
      -gravity center \
      -extent 1000 \
      -quality 90 \
      "$CACHE_DIR/wall.thmb" 2>/dev/null
  } &

  {
    # 2. Square thumbnail with zoom (500x500)
    magick "${source_image}[0]" \
      -strip \
      -distort SRT '1.8 0' \
      -thumbnail 500x500^ \
      -gravity center \
      -extent 500x500 \
      "$CACHE_DIR/wall.sqre" 2>/dev/null
  } &

  {
    # 3. Rofi square thumbnail (1250x1250)
    magick "${source_image}[0]" \
      -strip \
      -distort SRT '1.8 0' \
      -thumbnail 1250x1250^ \
      -gravity center \
      -extent 1250x1250 \
      "$CACHE_DIR/wall-rofi.sqre" 2>/dev/null
  } &

  {
    # 4. Blurred variant
    magick "${source_image}[0]" \
      -strip \
      -scale 10% \
      -blur 0x3 \
      -resize 100% \
      "$CACHE_DIR/wall.blur" 2>/dev/null
  } &

  # 5. Full-size PNG conversion (if needed)
  if [[ "$source_image" != *.png ]]; then
    {
      magick "${source_image}[0]" \
        -strip \
        -quality 95 \
        "$CACHE_DIR/wall.png" 2>/dev/null
    } &
  fi

  wait
  echo "Wallpaper variants complete" >&2
}

generate_material_colors() {
  local source_image="$1"

  if ! command -v matugen >/dev/null 2>&1; then
    return 0
  fi

  validate_media_file "$source_image" || return 1

  echo "Generating material design colors..." >&2

  if matugen image "$source_image" 2>/dev/null; then
    echo "Material colors generated successfully" >&2
  else
    echo "Warning: Material color generation failed" >&2
  fi
}

# ============================================================================
# Desktop-Specific Wallpaper Setters
# ============================================================================

set_hyprland_wallpaper() {
  local imagepath="$1"

  if ! command -v swww >/dev/null 2>&1; then
    echo "Error: swww not installed - cannot set Hyprland wallpaper" >&2
    return 1
  fi

  local cursor_pos
  cursor_pos=$(get_hyprland_cursor_position)

  if swww img "$imagepath" \
    --transition-step 100 \
    --transition-fps 120 \
    --transition-type grow \
    --transition-angle 30 \
    --transition-duration 1 \
    --transition-pos "$cursor_pos" 2>/dev/null; then
    echo "Hyprland wallpaper set: $imagepath" >&2
  else
    echo "Warning: swww command failed" >&2
    return 1
  fi

  # Generate additional assets
  generate_wallpaper_variants "$imagepath"
  generate_material_colors "$imagepath"

  # Copy to rofi background directory
  local rofi_images_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/images"
  if mkdir -p "$rofi_images_dir" 2>/dev/null; then
    if cp "$imagepath" "$rofi_images_dir/background.png" 2>/dev/null; then
      echo "Rofi background updated" >&2
    fi
  fi

  return 0
}

set_gnome_wallpaper() {
  local imagepath="$1"

  if ! command -v gsettings >/dev/null 2>&1; then
    echo "Error: gsettings not found - cannot set GNOME wallpaper" >&2
    return 1
  fi

  local file_uri="file://$imagepath"

  gsettings set org.gnome.desktop.background picture-uri "$file_uri" 2>/dev/null
  gsettings set org.gnome.desktop.background picture-uri-dark "$file_uri" 2>/dev/null

  echo "GNOME wallpaper set: $imagepath" >&2

  # Optional: Generate material colors with timeout to prevent hanging
  if command -v matugen >/dev/null 2>&1; then
    (
      timeout 3 bash -c "matugen image '$imagepath' 2>/dev/null" || \
        echo "Warning: Material color generation timed out" >&2
    ) &
  fi

  return 0
}

set_kde_wallpaper() {
  local imagepath="$1"

  if ! command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    echo "Error: plasma-apply-wallpaperimage not found - cannot set KDE wallpaper" >&2
    return 1
  fi

  plasma-apply-wallpaperimage "$imagepath" 2>/dev/null

  echo "KDE Plasma wallpaper set: $imagepath" >&2

  return 0
}

# ============================================================================
# Main Wallpaper Setter
# ============================================================================

set_wallpaper() {
  local filepath="$1"

  validate_media_file "$filepath" || return 1

  # Handle video wallpapers
  if is_video_file "$filepath"; then
    set_video_wallpaper "$filepath"
    return
  fi

  # Handle image wallpapers per desktop environment
  if is_hyprland; then
    set_hyprland_wallpaper "$filepath"
  elif is_gnome; then
    set_gnome_wallpaper "$filepath"
  elif is_kde; then
    set_kde_wallpaper "$filepath"
  else
    echo "Warning: No supported desktop environment detected" >&2
    echo "Detected: ${XDG_CURRENT_DESKTOP:-unknown}" >&2
    return 1
  fi

  echo "$filepath"
}

# ============================================================================
# Wallpaper Picker Functions
# ============================================================================

# --- Rofi Wallpaper Picker (Dependencies: rofi, wallcacher.sh, wlroots) ---
rofi_wallpaper_picker() {
  if ! command -v rofi >/dev/null 2>&1; then
    echo "Error: rofi not installed" >&2
    return 1
  fi

  local wallpaper_dir
  wallpaper_dir=$(resolve_wallpaper_directory) || return 1

  local thumb_cache="$CACHE_DIR/rofi-thumbs"
  mkdir -p "$thumb_cache"

  # Generate thumbnails (function from wallcacher.sh)
  declare -a media_files=()
  declare -a cache_files=()

  if ! generate_rofi_thumbnails "$wallpaper_dir" "$thumb_cache" media_files cache_files; then
    rofi -e "No media files found in $wallpaper_dir" 2>/dev/null
    return 1
  fi

  # Determine theme
  local theme_path="$HOME/.config/rofi/wallpaper/wallpaper.rasi"
  local theme_arg=""

  if [[ -f "$theme_path" ]]; then
    theme_arg="-theme $theme_path"
  else
    echo "Note: Using default rofi theme (custom theme not found)" >&2
  fi

  # Build rofi input with icons
  local rofi_input=""
  for i in "${!media_files[@]}"; do
    local filename
    filename=$(basename "${media_files[$i]}")

    if [[ -f "${cache_files[$i]}" ]]; then
      # Format: display_text\x00icon\x1f/path/to/thumb
      rofi_input+="${filename}\x00icon\x1f${cache_files[$i]}\n"
    else
      rofi_input+="${filename}\n"
    fi
  done

  # Launch rofi picker
  local selected_index
  selected_index=$(echo -ne "$rofi_input" | \
    rofi -dmenu -i \
      $theme_arg \
      -p " 󰸉  Select Wallpaper " \
      -format 'i' \
      -no-custom \
      -eh 1 \
      -kb-custom-1 "Alt+Left" \
      -kb-custom-2 "Alt+Right" 2>/dev/null)

  if [[ -n "$selected_index" ]]; then
    echo "${media_files[$selected_index]}"
  else
    return 1
  fi
}

# --- Yad File Picker (Dependencies: yad) ---
yad_wallpaper_picker() {
  if ! command -v yad >/dev/null 2>&1; then
    echo "Error: yad not installed" >&2
    echo "Install with: sudo apt install yad" >&2
    return 1
  fi

  local start_dir="${1:-}"

  if [[ -z "$start_dir" ]]; then
    start_dir=$(resolve_wallpaper_directory) || return 1
  fi

  cd "$start_dir" 2>/dev/null || cd "$HOME"

  echo "Using yad file picker with preview..." >&2

  local selected_file
  selected_file=$(yad --file \
    --title="Select Wallpaper" \
    --filename="$(pwd)/" \
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
    --button="Cancel:1" 2>/dev/null)

  local exit_code=$?
  if [[ $exit_code -eq 0 && -n "$selected_file" ]]; then
    echo "$selected_file"
    return 0
  else
    echo "Dialog cancelled by user" >&2
    return 1
  fi
}

# --- FZF File Picker (Dependencies: fzf, an image viewer like chafa/timg) ---
fzf_wallpaper_picker() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf not installed" >&2
    echo "Install with: sudo apt install fzf" >&2
    return 1
  fi

  local wallpaper_dir
  wallpaper_dir=$(resolve_wallpaper_directory) || return 1

  echo "Using fzf file picker with preview..." >&2

  # Check for image preview tools 
  local preview_cmd="file {}" # Default fallback
  if command -v chafa >/dev/null 2>&1; then
    preview_cmd="chafa -s 80x40 {}"
  elif command -v timg >/dev/null 2>&1; then
    preview_cmd="timg -g 80x40 {}"
  elif command -v catimg >/dev/null 2>&1; then
    preview_cmd="catimg -w 80 {}"
  elif command -v viu >/dev/null 2>&1; then
    preview_cmd="viu -w 80 {}"
  else
    echo "Note: Install chafa, timg, catimg, or viu for image preview" >&2
  fi

  # Find and select wallpaper
  local selected_file
  selected_file=$(find "$wallpaper_dir" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o \
    -iname "*.png" -o -iname "*.gif" -o \
    -iname "*.webp" -o -iname "*.bmp" -o \
    -iname "*.mp4" -o -iname "*.mov" -o \
    -iname "*.webm" \
  \) 2>/dev/null | \
  fzf --preview="$preview_cmd" \
      --preview-window=right:50% \
      --height=100% \
      --border \
      --prompt="Select Wallpaper > " \
      --header="Press ENTER to select, ESC to cancel" \
      --color="bg+:#2a2a2a,fg+:#ffffff,border:#444444,prompt:#0078d4")

  if [[ -n "$selected_file" && -f "$selected_file" ]]; then
    echo "$selected_file"
    return 0
  else
    echo "No wallpaper selected" >&2
    return 1
  fi
}

# --- GUI File Picker Fallback (Dependencies: zenity or kdialog) ---
open_gui_file_picker() {
  local start_dir="${1:-}"
  local selected_file=""

  # Determine starting directory
  if [[ -z "$start_dir" ]]; then
    start_dir=$(resolve_wallpaper_directory) || { start_dir="$HOME"; }
  fi

  cd "$start_dir" 2>/dev/null || cd "$HOME"

  if command -v zenity >/dev/null 2>&1; then
    echo "Using zenity file picker..." >&2

    selected_file=$(zenity --file-selection \
      --title="Select Wallpaper" \
      --filename="$(pwd)/" \
      --file-filter="Images (jpg,png,gif,webp) | *.jpg *.jpeg *.png *.gif *.bmp *.webp" \
      --file-filter="Videos (mp4,mov,webm) | *.mp4 *.mov *.webm" \
      --file-filter="All files | *" 2>/dev/null)

    local exit_code=$?
    if [[ $exit_code -eq 0 && -n "$selected_file" ]]; then
      echo "$selected_file"
      return 0
    elif [[ $exit_code -eq 1 ]]; then
      echo "Dialog cancelled by user" >&2
      return 1
    else
      echo "Dialog error (exit code: $exit_code)" >&2
      return 1
    fi

  elif command -v kdialog >/dev/null 2>&1; then
    echo "Using kdialog file picker..." >&2

    selected_file=$(kdialog --getopenfilename "$(pwd)" \
      "*.jpg *.jpeg *.png *.gif *.bmp *.webp *.mp4 *.mov *.webm|Media Files" 2>/dev/null)

    local exit_code=$?
    if [[ $exit_code -eq 0 && -n "$selected_file" ]]; then
      echo "$selected_file"
      return 0
    else
      echo "Dialog cancelled or error (exit code: $exit_code)" >&2
      return 1
    fi

  else
    echo "Error: No GUI file picker available (install zenity or kdialog)" >&2
    return 1
  fi
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
  initialize

  # Parse flags
  local use_rofi_flag=false
  local use_yad_flag=false
  local use_fzf_flag=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--rofi)
        use_rofi_flag=true
        shift
        ;;
      --yad)
        use_yad_flag=true
        shift
        ;;
      --fzf)
        use_fzf_flag=true
        shift
        ;;
      *)
        # Assume it's a file path
        break
        ;;
    esac
  done

  # Handle direct file path argument
  if [[ -n "${1:-}" ]]; then
    set_wallpaper "$1"
    return
  fi

  # No argument - open picker
  local selected_file=""
  local wallpaper_dir
  wallpaper_dir=$(resolve_wallpaper_directory) || exit 1

  # Determine picker method based on desktop environment and flags
  if [[ "$use_yad_flag" == true ]]; then
    selected_file=$(yad_wallpaper_picker "$wallpaper_dir") || { exit 1; }

  elif [[ "$use_fzf_flag" == true ]]; then
    selected_file=$(fzf_wallpaper_picker) || { exit 1; }

  elif [[ "$use_rofi_flag" == true ]]; then
    if is_gnome || is_kde; then
      echo "Warning: Rofi is best for Hyprland/Sway. Falling back to GUI." >&2
      selected_file=$(open_gui_file_picker "$wallpaper_dir") || { exit 1; }
    elif command -v rofi >/dev/null 2>&1; then
      selected_file=$(rofi_wallpaper_picker) || { exit 1; }
    else
      echo "Error: rofi not installed" >&2
      exit 1
    fi

  elif is_hyprland && command -v rofi >/dev/null 2>&1; then
    # Default for Hyprland
    selected_file=$(rofi_wallpaper_picker) || { exit 1; }

  else
    # Default for GNOME, KDE, or when rofi/fzf are unavailable
    selected_file=$(open_gui_file_picker "$wallpaper_dir") || { exit 1; }
  fi

  # Set the selected wallpaper
  if [[ -n "$selected_file" && -f "$selected_file" ]]; then
    set_wallpaper "$selected_file"
  else
    echo "Error: Invalid file selection" >&2
    exit 1
  fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
