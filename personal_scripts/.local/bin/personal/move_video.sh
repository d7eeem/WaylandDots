#!/usr/bin/env bash

action="$1"
file="$2"

# The folder where the video lives
BASE_DIR="$(dirname "$file")"

# Create KEEP/DELETE next to the video files
KEEP_DIR="${BASE_DIR}/KEEP"
DELETE_DIR="${BASE_DIR}/DELETE"

mkdir -p "$KEEP_DIR"
mkdir -p "$DELETE_DIR"

case "$action" in
  keep)
    mv -n -- "$file" "$KEEP_DIR/" && echo "KEPT: $file"
    ;;
  delete)
    mv -n -- "$file" "$DELETE_DIR/" && echo "DELETED: $file"
    ;;
  *)
    echo "Unknown action: $action" >&2
    exit 2
    ;;
esac
