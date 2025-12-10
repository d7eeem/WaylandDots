#!/bin/bash

# Eden Linux Auto-Update Wrapper
# Runs update only if Eden is not currently running

INSTALL_DIR="$HOME/Applications"
APP_NAME="Eden-Linux"
LOG_FILE="$HOME/.local/share/eden-updater/auto-update.log"

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== Auto-update check started ==="

# Check if Eden is running
if pgrep -f "$APP_NAME" > /dev/null; then
    log "Eden Linux is currently running. Skipping update."
    exit 0
fi

log "Eden Linux is not running. Proceeding with update check..."

# Run the updater script non-interactively
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "y" | "$SCRIPT_DIR/eden_updater.sh" >> "$LOG_FILE" 2>&1

log "=== Auto-update check completed ==="
