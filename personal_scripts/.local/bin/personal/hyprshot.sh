#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

#!/bin/bash

# Load environment variables
if [ -f ~/.env ]; then
  export $(grep -v '^#' ~/.env | xargs)
fi

# Configuration
SAVE_DIR="$HOME/Nextcloud/Hyprshot"
TEMP_DIR="/tmp/screencast"
XBACKBONE_URL="https://xback.aloqaili.xyz/upload"
XBACKBONE_TOKEN="${XBACK_BONE}"

# Create directories if they don't exist
mkdir -p "$SAVE_DIR"
mkdir -p "$TEMP_DIR"

# Check dependencies
check_deps() {
    ERRORS=0
    MISSING_DEPS=()
    
    local REQUIRED_CMDS="jq curl wl-copy notify-send hyprshot"
    local VIDEO_CMDS="wf-recorder slurp"
    
    for cmd in $REQUIRED_CMDS; do
        if ! command -v "$cmd" &> /dev/null; then
            MISSING_DEPS+=("$cmd")
            ERRORS=1
        fi
    done
    
    # Only check video deps if doing video operations
    if [[ "$1" == "vm" ]] || [[ "$1" == "vr" ]] || [[ "$1" == "rofi" ]]; then
        for cmd in $VIDEO_CMDS; do
            if ! command -v "$cmd" &> /dev/null; then
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

# Upload file to XBackbone
upload() {
    local FILE="$1"
    
    if [ ! -f "$FILE" ]; then
        notify-send "Upload Error" "File does not exist: $FILE"
        exit 1
    fi
    
    # Check if token is set
    if [ -z "$XBACKBONE_TOKEN" ]; then
        notify-send "Upload Error" "XBACK_BONE token not set in ~/.env"
        exit 1
    fi
    
    notify-send "Uploading..." "Please wait..."
    
    RESPONSE="$(curl -s -F "token=$XBACKBONE_TOKEN" -F "upload=@${FILE}" "$XBACKBONE_URL")"
    
    # Debug: log response
    echo "Response: $RESPONSE" >> /tmp/xbackbone_upload.log
    
    if [[ "$(echo "${RESPONSE}" | jq -r '.message')" == "OK" ]]; then
        URL="$(echo "${RESPONSE}" | jq -r '.url')"
        echo "${URL}" | wl-copy
        notify-send "Upload Completed" "<a href='${URL}'>${URL}</a>"
        exit 0
    else
        MESSAGE="$(echo "${RESPONSE}" | jq -r '.message')"
        if [ $? -ne 0 ]; then
            notify-send "Upload Error" "Unexpected response from server. Check /tmp/xbackbone_upload.log"
            exit 1
        fi
        notify-send "Upload Error" "${MESSAGE}"
        exit 1
    fi
}

# Screenshot functions (compatible with your existing keybinds)
sm() {
    # Screenshot Monitor
    local FILENAME="screenshot_$(date +%Y%m%d_%H%M%S).png"
    hyprshot -m output -m active -o "$SAVE_DIR" --filename "$FILENAME"
    local FILE="$SAVE_DIR/$FILENAME"
    
    # Wait a moment for file to be written
    sleep 0.2
    
    if [ -f "$FILE" ]; then
        upload "$FILE"
    else
        notify-send "Screenshot Error" "Failed to capture screenshot"
    fi
}

sw() {
    # Screenshot Window
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

sa() {
    # Screenshot Area/Region
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
    notify-send "Recording Started" "Recording full monitor. Press Super+Shift+R to stop."
    wf-recorder -f "$FILE" &
    RECORDER_PID=$!
    echo $RECORDER_PID > "$TEMP_DIR/recorder.pid"
    
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
    
    notify-send "Recording Started" "Recording selected region. Press Super+Shift+R to stop."
    wf-recorder -g "$GEOMETRY" -f "$FILE" &
    RECORDER_PID=$!
    echo $RECORDER_PID > "$TEMP_DIR/recorder.pid"
    
    wait $RECORDER_PID
    
    if [ -f "$FILE" ]; then
        notify-send "Recording Stopped" "Uploading..."
        upload "$FILE"
    fi
}

# Stop recording
stop() {
    if pgrep -x "wf-recorder" > /dev/null; then
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
    OPTIONS="󰹑  Screenshot - Monitor
󰖨  Screenshot - Window
󰩭  Screenshot - Region
󰐌  Screencast - Monitor
󰕧  Screencast - Region
󰓛  Stop Recording"
    
    # Check if custom theme exists, otherwise use inline theme
    if [ -f "$ROFI_CONFIG/style_1.rasi" ]; then
        CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i \
            -p "  Capture" \
            -theme "$ROFI_CONFIG/style_1.rasi" \
            -theme-str 'configuration { display-drun: "  "; drun-prompt: "  "; }' \
            -theme-str 'listview { lines: 6; }' \
            -theme-str 'window { width: 425px; height: 400px; }')
    else
        CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i \
            -p "  Capture" \
            -theme-str 'window { width: 425px; height: 400px; border-radius: 12px; padding: 15px; }' \
            -theme-str 'listview { lines: 6; spacing: 8px; }' \
            -theme-str 'element { padding: 10px 15px; border-radius: 8px; }' \
            -theme-str 'inputbar { padding: 10px 15px; border-radius: 8px; margin-bottom: 12px; }')
    fi
    
    case "$CHOICE" in
        *"Screenshot - Monitor"*)
            sm
            ;;
        *"Screenshot - Window"*)
            sw
            ;;
        *"Screenshot - Region"*)
            sa
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
    vm)
        vm
        ;;
    vr)
        vr
        ;;
    stop)
        stop
        ;;
    rofi|*)
        rofi_menu
        ;;
esac
