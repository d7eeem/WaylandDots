#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
#

#!/usr/bin/env bash

if [ -f ~/.env ]; then
  export $(grep -v '^#' ~/.env | xargs)
fi

# Configuration
SAVE_DIR="$HOME/Nextcloud/Hyprshot"
TEMP_DIR="/tmp/screencast"
XBACKBONE_URL="${XXBACKBONE_URL}"
XBACKBONE_TOKEN="${XBACK_BONE}"

# Annotation tool preference (satty or swappy)
ANNOTATION_TOOL="satty" # Change to "swappy" if you prefer swappy

# Create directories if they don't exist
mkdir -p "$SAVE_DIR"
mkdir -p "$TEMP_DIR"

# Check dependencies
check_deps() {
  ERRORS=0
  MISSING_DEPS=()

  local REQUIRED_CMDS="jq curl wl-copy notify-send hyprshot grim slurp"
  local VIDEO_CMDS="wf-recorder"

  for cmd in $REQUIRED_CMDS; do
    if ! command -v "$cmd" &>/dev/null; then
      MISSING_DEPS+=("$cmd")
      ERRORS=1
    fi
  done

  # Check annotation tool
  if ! command -v "$ANNOTATION_TOOL" &>/dev/null; then
    MISSING_DEPS+=("$ANNOTATION_TOOL")
    ERRORS=1
  fi

  # Only check video deps if doing video operations
  if [[ "$1" == "vm" ]] || [[ "$1" == "vr" ]] || [[ "$1" == "rofi" ]]; then
    for cmd in $VIDEO_CMDS; do
      if ! command -v "$cmd" &>/dev/null; then
        MISSING_DEPS+=("$cmd")
        ERRORS=1
      fi
    done
  fi

  if [ "$ERRORS" -eq 1 ]; then
    notify-send "Missing Dependencies" "Please install: ${MISSING_DEPS[*]}"
    exit 1
  fi
}

upload() {
  local FILE="$1"

  if [ ! -f "$FILE" ]; then
    notify-send "Upload Error" "File does not exist: $FILE"
    return 1
  fi

  if [ -z "$XBACKBONE_TOKEN" ]; then
    notify-send "Upload Error" "XBACK_BONE token not set in ~/.env"
    return 1
  fi

  notify-send "Uploading..." "Please wait..."

  RESPONSE="$(curl -s -F "token=$XBACKBONE_TOKEN" -F "upload=@${FILE}" "$XBACKBONE_URL")"

  echo "Response: $RESPONSE" >>/tmp/xbackbone_upload.log

  if [[ "$(echo "$RESPONSE" | jq -r '.message')" == "OK" ]]; then
    URL="$(echo "$RESPONSE" | jq -r '.url')"

    echo "$URL" | wl-copy

    NOTIFICATION_ACTION=$(
      notify-send \
        -u normal \
        "Upload Completed" \
        "$URL" \
        --action="open=Open in Browser"
    )

    if [[ "$NOTIFICATION_ACTION" == "open" ]]; then
      "$HOME/.local/bin/hypr/zen.sh" "$URL" &
    fi

    return 0
  else
    MESSAGE="$(echo "$RESPONSE" | jq -r '.message')"
    notify-send "Upload Error" "${MESSAGE:-Unexpected response from server}"
    return 1
  fi
}

# Open file in annotation tool and handle save/upload
annotate_and_upload() {
  local TEMP_FILE="$1"
  local FINAL_FILE="$SAVE_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

  if [ "$ANNOTATION_TOOL" = "satty" ]; then
    # Satty configuration
    satty --filename "$TEMP_FILE" \
      --output-filename "$FINAL_FILE" \
      --early-exit \
      --copy-command "wl-copy" \
      --initial-tool brush

    # Check if user saved the file and upload automatically
    if [ -f "$FINAL_FILE" ]; then
      upload "$FINAL_FILE"
    fi
  else
    # Swappy configuration
    swappy -f "$TEMP_FILE" -o "$FINAL_FILE"

    # Check if user saved the file and upload automatically
    if [ -f "$FINAL_FILE" ]; then
      upload "$FINAL_FILE"
    fi
  fi

  # Clean up temp file
  rm -f "$TEMP_FILE"
}

# Screenshot functions with annotation
sm() {
  # Screenshot Monitor
  local TEMP_FILE="$TEMP_DIR/temp_screenshot_$(date +%Y%m%d_%H%M%S).png"
  hyprshot -m output -m active -o "$TEMP_DIR" --filename "$(basename "$TEMP_FILE")"

  sleep 0.2

  if [ -f "$TEMP_FILE" ]; then
    annotate_and_upload "$TEMP_FILE"
  else
    notify-send "Screenshot Error" "Failed to capture screenshot"
  fi
}

sw() {
  # Screenshot Window
  local TEMP_FILE="$TEMP_DIR/temp_screenshot_$(date +%Y%m%d_%H%M%S).png"
  hyprshot -m window -o "$TEMP_DIR" --filename "$(basename "$TEMP_FILE")"

  sleep 0.2

  if [ -f "$TEMP_FILE" ]; then
    annotate_and_upload "$TEMP_FILE"
  else
    notify-send "Screenshot Error" "Failed to capture screenshot"
  fi
}

sa() {
  # Screenshot Area/Region
  local TEMP_FILE="$TEMP_DIR/temp_screenshot_$(date +%Y%m%d_%H%M%S).png"
  hyprshot -m region -o "$TEMP_DIR" --filename "$(basename "$TEMP_FILE")"

  sleep 0.2

  if [ -f "$TEMP_FILE" ]; then
    annotate_and_upload "$TEMP_FILE"
  else
    notify-send "Screenshot Error" "Failed to capture screenshot"
  fi
}

# Quick screenshot functions (no annotation, direct upload)
sm_quick() {
  local FILENAME="screenshot_$(date +%Y%m%d_%H%M%S).png"
  hyprshot -m output -m active -o "$SAVE_DIR" --filename "$FILENAME"
  local FILE="$SAVE_DIR/$FILENAME"

  sleep 0.2

  if [ -f "$FILE" ]; then
    upload "$FILE"
  else
    notify-send "Screenshot Error" "Failed to capture screenshot"
  fi
}

sw_quick() {
  local FILENAME="screenshot_$(date +%Y%m%d_%H%M%S).png"
  hyprshot -m window -o "$SAVE_DIR" --filename "$FILENAME"
  local FILE="$SAVE_DIR/$FILENAME"

  sleep 0.2

  if [ -f "$FILE" ]; then
    upload "$FILE"
  else
    notify-send "Screenshot Error" "Failed to capture screenshot"
  fi
}

sa_quick() {
  local FILENAME="screenshot_$(date +%Y%m%d_%H%M%S).png"
  hyprshot -m region -o "$SAVE_DIR" --filename "$FILENAME"
  local FILE="$SAVE_DIR/$FILENAME"

  sleep 0.2

  if [ -f "$FILE" ]; then
    upload "$FILE"
  else
    notify-send "Screenshot Error" "Failed to capture screenshot"
  fi
}

# Screencast functions
vm() {
  # Video Monitor
  local FILE="$TEMP_DIR/screencast_$(date +%Y%m%d_%H%M%S).mp4"
  notify-send "Recording Started" "Recording full monitor. Press Super+Ctrl+R to stop."
  wf-recorder -f "$FILE" &
  RECORDER_PID=$!
  echo $RECORDER_PID >"$TEMP_DIR/recorder.pid"

  wait $RECORDER_PID

  if [ -f "$FILE" ]; then
    notify-send "Recording Stopped" "Uploading..."
    upload "$FILE"
  fi
}

vr() {
  # Video Region
  local FILE="$TEMP_DIR/screencast_$(date +%Y%m%d_%H%M%S).mp4"
  local GEOMETRY=$(slurp)

  if [ -z "$GEOMETRY" ]; then
    notify-send "Recording Cancelled" "No region selected"
    exit 0
  fi

  notify-send "Recording Started" "Recording selected region. Press Super+Ctrl+R to stop."
  wf-recorder -g "$GEOMETRY" -f "$FILE" &
  RECORDER_PID=$!
  echo $RECORDER_PID >"$TEMP_DIR/recorder.pid"

  wait $RECORDER_PID

  if [ -f "$FILE" ]; then
    notify-send "Recording Stopped" "Uploading..."
    upload "$FILE"
  fi
}

# Stop recording
stop() {
  if pgrep -x "wf-recorder" >/dev/null; then
    pkill -SIGINT wf-recorder
    rm -f "$TEMP_DIR/recorder.pid"
    notify-send "Recording Stopped" "Processing and uploading video..."
  else
    notify-send "No Active Recording" "No recording to stop"
  fi
}

# Rofi menu for interactive selection
rofi_menu() {
  # Get rofi config directory
  ROFI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/clipboard"

  # Create menu options
  OPTIONS="󰹑  Screenshot - Monitor (Annotate)
󰖨  Screenshot - Window (Annotate)
󰩭  Screenshot - Region (Annotate)
󰄀  Quick Screenshot - Monitor
󰖯  Quick Screenshot - Window
  Quick Screenshot - Region
󰐌  Screencast - Monitor
󰕧  Screencast - Region
󰓛  Stop Recording"

  # Check if custom theme exists, otherwise use inline theme
  if [ -f "$ROFI_CONFIG/style_1.rasi" ]; then
    CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i \
      -p "  Capture" \
      -theme "$ROFI_CONFIG/style_1.rasi" \
      -theme-str 'configuration { display-drun: "  "; drun-prompt: "  "; }' \
      -theme-str 'listview { lines: 9; }' \
      -theme-str 'window { width: 500px; height: 550px; }')
  else
    CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i \
      -p "  Capture" \
      -theme-str 'window { width: 500px; height: 550px; border-radius: 12px; padding: 15px; }' \
      -theme-str 'listview { lines: 9; spacing: 8px; }' \
      -theme-str 'element { padding: 10px 15px; border-radius: 8px; }' \
      -theme-str 'inputbar { padding: 10px 15px; border-radius: 8px; margin-bottom: 12px; }')
  fi

  case "$CHOICE" in
  *"Monitor (Annotate)"*)
    sm
    ;;
  *"Window (Annotate)"*)
    sw
    ;;
  *"Region (Annotate)"*)
    sa
    ;;
  *"Quick Screenshot - Monitor"*)
    sm_quick
    ;;
  *"Quick Screenshot - Window"*)
    sw_quick
    ;;
  *"Quick Screenshot - Region"*)
    sa_quick
    ;;
  *"Screencast - Monitor"*)
    vm
    ;;
  *"Screencast - Region"*)
    vr
    ;;
  *"Stop Recording"*)
    stop
    ;;
  *)
    exit 0
    ;;
  esac
}

# Main execution
MODE="${1}"

check_deps "$MODE"

case "$MODE" in
sm)
  sm
  ;;
sw)
  sw
  ;;
sa)
  sa
  ;;
sm_quick)
  sm_quick
  ;;
sw_quick)
  sw_quick
  ;;
sa_quick)
  sa_quick
  ;;
vm)
  vm
  ;;
vr)
  vr
  ;;
stop)
  stop
  ;;
rofi | *)
  rofi_menu
  ;;
esac
