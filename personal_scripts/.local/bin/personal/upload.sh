#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem


# File upload script for uploader.*.xyz
# Supports single/multiple files via CLI or yazi selection

# Load environment variables safely
if [ -f ~/.env ]; then
  set -a
  source ~/.env
  set +a
fi

# Use corrected variable name with fallback
UPLOAD_URL=${UPLOAD_URL_GLOBAL:-${UPLOAD_URL_GLOBLA}}

# Validate upload URL is set
if [ -z "$UPLOAD_URL" ]; then
    echo -e "\033[0;31mError: UPLOAD_URL not set. Please configure UPLOAD_URL_GLOBAL in ~/.env\033[0m"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track upload statistics globally
SUCCESS_COUNT=0
FAIL_COUNT=0
UPLOADED_URLS=()

# Function to send desktop notification
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    local url="${4:-}"
    
    if command -v notify-send &> /dev/null; then
        # Linux (notify-send) - supports actions for swaync, dunst, mako
        if [ -n "$url" ]; then
            # Add action to open URL in browser
            notify-send -u "$urgency" -a "Upload Script" "$title" "$message" \
                --action="default=Open in Browser" | while read action; do
                if [ "$action" = "default" ]; then
                    # Try different browser launchers
                    if command -v xdg-open &> /dev/null; then
                        xdg-open "$url" &
                    elif command -v open &> /dev/null; then
                        open "$url" &
                    elif command -v firefox &> /dev/null; then
                        firefox "$url" &
                    elif command -v chromium &> /dev/null; then
                        chromium "$url" &
                    fi
                fi
            done &
        else
            notify-send -u "$urgency" -a "Upload Script" "$title" "$message"
        fi
    elif command -v osascript &> /dev/null; then
        # macOS
        osascript -e "display notification \"$message\" with title \"$title\""
    elif command -v powershell.exe &> /dev/null; then
        # WSL/Windows
        powershell.exe -Command "
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
            \$template = @\"
            <toast>
                <visual>
                    <binding template='ToastText02'>
                        <text id='1'>$title</text>
                        <text id='2'>$message</text>
                    </binding>
                </visual>
            </toast>
\"@
            \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            \$xml.LoadXml(\$template)
            \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Upload Script').Show(\$toast)
        " 2>/dev/null
    fi
}

# Cleanup and notification on exit
cleanup_and_notify() {
    local exit_code=$?
    
    # Only send notification if files were actually uploaded
    if [ $SUCCESS_COUNT -gt 0 ] || [ $FAIL_COUNT -gt 0 ]; then
        local total=$((SUCCESS_COUNT + FAIL_COUNT))
        local title="Upload Complete"
        local message
        local urgency="normal"
        local notification_url=""
        
        if [ $FAIL_COUNT -eq 0 ]; then
            # All successful
            if [ $SUCCESS_COUNT -eq 1 ]; then
                message="✓ 1 file uploaded successfully"
            else
                message="✓ $SUCCESS_COUNT files uploaded successfully"
            fi
            urgency="normal"
        elif [ $SUCCESS_COUNT -eq 0 ]; then
            # All failed
            if [ $FAIL_COUNT -eq 1 ]; then
                message="✗ 1 file failed to upload"
            else
                message="✗ $FAIL_COUNT files failed to upload"
            fi
            urgency="critical"
        else
            # Mixed results
            message="✓ $SUCCESS_COUNT succeeded, ✗ $FAIL_COUNT failed"
            urgency="normal"
        fi
        
        # Add URL to notification if only one file was uploaded successfully
        if [ $SUCCESS_COUNT -eq 1 ] && [ ${#UPLOADED_URLS[@]} -eq 1 ]; then
            notification_url="${UPLOADED_URLS[0]}"
            message="$message
${notification_url}"
        fi
        
        send_notification "$title" "$message" "$urgency" "$notification_url"
    fi
    
    exit $exit_code
}

# Set trap to call cleanup on exit
trap cleanup_and_notify EXIT INT TERM

# Function to upload a single file
upload_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File '$file' not found${NC}"
        return 1
    fi
    
    # Get file size for display
    local filesize=$(du -h "$file" | cut -f1)
    
    echo -e "${YELLOW}Uploading: $(basename "$file") (${filesize})${NC}"
    
    # Upload with progress bar if file is large
    response=$(curl -s -w "\n%{http_code}" -X POST -F "file=@$file" "$UPLOAD_URL" 2>&1)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    # Check for success (200 OK or 201 Created)
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo -e "${GREEN}✓ Successfully uploaded: $(basename "$file")${NC}"
        ((SUCCESS_COUNT++))
        
        # Try to extract URL from response
        local extracted_url=""
        
        # First try to extract full URL (https://...)
        if echo "$body" | grep -qE 'https?://[^"[:space:]]+'; then
            extracted_url=$(echo "$body" | grep -oE 'https?://[^"[:space:]]+' | head -1)
        # Then try to extract from JSON "url" field
        elif echo "$body" | grep -qE '"url"[[:space:]]*:[[:space:]]*"[^"]+"'; then
            extracted_url=$(echo "$body" | grep -oE '"url"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed 's/"url"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
            # If it's a relative path, prepend the base URL
            if [[ "$extracted_url" == /* ]]; then
                # Extract base URL from UPLOAD_URL (e.g., https://uploader.example.xyz)
                base_url=$(echo "$UPLOAD_URL" | grep -oE 'https?://[^/]+')
                extracted_url="${base_url}${extracted_url}"
            fi
        fi
        
        if [ -n "$extracted_url" ]; then
            UPLOADED_URLS+=("$extracted_url")
            echo -e "${BLUE}URL: $extracted_url${NC}"
            
            # Copy to clipboard if available
            if command -v wl-copy &> /dev/null; then
                # Wayland (wl-clipboard)
                echo "$extracted_url" | wl-copy
                echo -e "${GREEN}(Copied to clipboard)${NC}"
            elif command -v xclip &> /dev/null; then
                # X11 (xclip)
                echo "$extracted_url" | xclip -selection clipboard
                echo -e "${GREEN}(Copied to clipboard)${NC}"
            elif command -v pbcopy &> /dev/null; then
                # macOS
                echo "$extracted_url" | pbcopy
                echo -e "${GREEN}(Copied to clipboard)${NC}"
            fi
        else
            echo "$body"
        fi
        echo ""
        return 0
    else
        echo -e "${RED}✗ Failed to upload: $(basename "$file") (HTTP $http_code)${NC}"
        ((FAIL_COUNT++))
        echo "$body"
        echo ""
        return 1
    fi
}

# Function to use yazi for file selection
upload_with_yazi() {
    if ! command -v yazi &> /dev/null; then
        echo -e "${RED}Error: yazi is not installed${NC}"
        echo "Install with: cargo install yazi-fm"
        exit 1
    fi
    
    # Create temporary file for yazi selection
    tmp_file=$(mktemp)
    
    # Run yazi and capture selected files
    yazi --chooser-file="$tmp_file"
    
    # Check if files were selected
    if [ ! -s "$tmp_file" ]; then
        echo -e "${YELLOW}No files selected${NC}"
        rm "$tmp_file"
        exit 0
    fi
    
    # Count total files
    total_files=$(wc -l < "$tmp_file")
    current=0
    
    echo -e "${BLUE}Uploading $total_files file(s)...${NC}"
    echo ""
    
    # Upload each selected file
    while IFS= read -r file; do
        ((current++))
        echo -e "${BLUE}[$current/$total_files]${NC}"
        upload_file "$file"
    done < "$tmp_file"
    
    rm "$tmp_file"
}

# Display usage information
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [FILES...]

Upload files to $UPLOAD_URL

OPTIONS:
    -y, --yazi      Launch yazi file manager for selection
    -h, --help      Show this help message

EXAMPLES:
    $(basename "$0")                    # Launch yazi for file selection
    $(basename "$0") file.txt           # Upload single file
    $(basename "$0") file1.txt file2.jpg # Upload multiple files
    $(basename "$0") --yazi             # Explicitly launch yazi

EOF
}

# Main script logic
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -y|--yazi)
        upload_with_yazi
        ;;
    "")
        # No arguments - launch yazi
        echo "No files specified. Launching yazi for file selection..."
        upload_with_yazi
        ;;
    *)
        # Files provided as arguments
        total_files=$#
        current=0
        
        echo -e "${BLUE}Uploading $total_files file(s)...${NC}"
        echo ""
        
        for file in "$@"; do
            ((current++))
            echo -e "${BLUE}[$current/$total_files]${NC}"
            upload_file "$file"
        done
        
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ Successfully uploaded: $SUCCESS_COUNT${NC}"
        [ $FAIL_COUNT -gt 0 ] && echo -e "${RED}✗ Failed uploads: $FAIL_COUNT${NC}"
        ;;
esac
