#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem


# Rofi Thumbnail Generator
# Generates and caches thumbnails for image and video files
# Compatible with HyDE-style thumbnail format

set -euo pipefail

# Configuration
readonly THUMBNAIL_SIZE="500x500"
readonly THUMBNAIL_EXTENSION=".sqre"
readonly MAX_PARALLEL_JOBS=8
readonly SEARCH_DEPTH=3

# Supported file extensions
readonly IMAGE_EXTENSIONS=("jpg" "jpeg" "png" "gif" "bmp" "webp")
readonly VIDEO_EXTENSIONS=("mp4" "mov" "webm")

# Generate find expression for supported media types
_build_find_expression() {
  local -a expr=()
  
  for ext in "${IMAGE_EXTENSIONS[@]}" "${VIDEO_EXTENSIONS[@]}"; do
    expr+=("-o" "-iname" "*.${ext}")
  done
  
  # Remove leading -o
  echo "${expr[@]:1}"
}

# Calculate MD5 hash for a file path
_calculate_hash() {
  local filepath="$1"
  echo -n "$filepath" | md5sum | cut -d' ' -f1
}

# Generate single thumbnail using ImageMagick
_generate_thumbnail() {
  local source_file="$1"
  local output_file="$2"
  local temp_file="${output_file}.tmp.png"
  
  if magick "${source_file}[0]" \
    -strip \
    -thumbnail "${THUMBNAIL_SIZE}^" \
    -gravity center \
    -extent "${THUMBNAIL_SIZE}" \
    "$temp_file" 2>/dev/null; then
    mv "$temp_file" "$output_file"
    return 0
  else
    rm -f "$temp_file" 2>/dev/null
    return 1
  fi
}

# Discover media files in directory
_discover_media_files() {
  local search_dir="$1"
  local -n files_array="$2"
  
  local find_expr
  find_expr=$(_build_find_expression)
  
  while IFS= read -r -d '' file; do
    files_array+=("$file")
  done < <(find "$search_dir" \
    -maxdepth "$SEARCH_DEPTH" \
    -type f \
    \( $find_expr \) \
    -print0 2>/dev/null | sort -z)
}

# Map media files to their cache paths
_map_cache_paths() {
  local cache_dir="$1"
  local -n source_files="$2"
  local -n cache_paths="$3"
  
  for file in "${source_files[@]}"; do
    local hash
    hash=$(_calculate_hash "$file")
    cache_paths+=("${cache_dir}/${hash}${THUMBNAIL_EXTENSION}")
  done
}

# Generate missing thumbnails in parallel
_generate_missing_thumbnails() {
  local -n source_files="$1"
  local -n cache_paths="$2"
  
  local total=${#source_files[@]}
  local generated=0
  local pending=0
  
  for i in "${!source_files[@]}"; do
    local source="${source_files[$i]}"
    local cache="${cache_paths[$i]}"
    
    if [[ -f "$cache" ]]; then
      continue
    fi
    
    echo "  [$(($i + 1))/$total] Generating: $(basename "$source")" >&2
    _generate_thumbnail "$source" "$cache" &
    
    ((pending++))
    ((generated++))
    
    # Throttle parallel jobs
    if ((pending >= MAX_PARALLEL_JOBS)); then
      wait -n 2>/dev/null || true
      ((pending--))
    fi
  done
  
  # Wait for remaining jobs
  wait
  
  echo "$generated"
}

# Main thumbnail generation function
# Usage: generate_rofi_thumbnails <media_dir> <cache_dir> <files_array_name> <cache_array_name>
generate_rofi_thumbnails() {
  local media_dir="$1"
  local cache_dir="$2"
  local -n output_files="$3"
  local -n output_cache="$4"
  
  # Validate inputs
  if [[ ! -d "$media_dir" ]]; then
    echo "Error: Media directory does not exist: $media_dir" >&2
    return 1
  fi
  
  # Ensure cache directory exists
  if ! mkdir -p "$cache_dir" 2>/dev/null; then
    echo "Error: Cannot create cache directory: $cache_dir" >&2
    return 1
  fi
  
  # Discover media files
  echo "Scanning $media_dir for media files..." >&2
  _discover_media_files "$media_dir" output_files
  
  local file_count=${#output_files[@]}
  if ((file_count == 0)); then
    echo "No media files found in $media_dir" >&2
    return 1
  fi
  
  # Map cache paths
  _map_cache_paths "$cache_dir" output_files output_cache
  
  # Check for ImageMagick
  if ! command -v magick >/dev/null 2>&1; then
    echo "Warning: ImageMagick not installed - thumbnails cannot be generated" >&2
    echo "Found $file_count media files (thumbnails unavailable)" >&2
    return 0
  fi
  
  # Generate missing thumbnails
  echo "Checking thumbnail cache..." >&2
  local generated
  generated=$(_generate_missing_thumbnails output_files output_cache)
  
  # Summary
  if ((generated > 0)); then
    echo "Generated $generated new thumbnails" >&2
  fi
  echo "Ready: $file_count media files available" >&2
  
  return 0
}

# Show usage when executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cat << 'EOF'
Rofi Thumbnail Generator
========================

A library for generating and caching thumbnails for rofi media pickers.

USAGE:
  Source this script in your bash code:
    source rofi-thumbnail-generator.sh

  Then call the main function:
    generate_rofi_thumbnails <media_dir> <cache_dir> <files_var> <cache_var>

PARAMETERS:
  media_dir    Directory containing media files (images/videos)
  cache_dir    Directory to store thumbnail cache
  files_var    Name of array variable to receive file paths
  cache_var    Name of array variable to receive cache paths

EXAMPLE:
  #!/usr/bin/env bash
  source rofi-thumbnail-generator.sh

  declare -a media_files=()
  declare -a cache_files=()

  if generate_rofi_thumbnails \
      "$HOME/Pictures" \
      "$HOME/.cache/thumbnails" \
      media_files \
      cache_files; then
    echo "Found ${#media_files[@]} files"
    for i in "${!media_files[@]}"; do
      echo "${media_files[$i]} -> ${cache_files[$i]}"
    done
  fi

REQUIREMENTS:
  - bash 4.0+
  - ImageMagick (magick command)
  - find, md5sum, sort

THUMBNAIL FORMAT:
  - Size: 500x500 pixels (square, center-cropped)
  - Format: PNG
  - Extension: .sqre (HyDE compatible)
  - Naming: MD5 hash of source file path

EOF
  exit 0
fi
