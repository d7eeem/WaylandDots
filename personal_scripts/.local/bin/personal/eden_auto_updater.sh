#!/bin/bash

# Eden Linux Auto-Updater Setup Script
# This creates either a systemd timer or crontab entry to check for updates every 12 hours

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATER_SCRIPT="$SCRIPT_DIR/eden_updater.sh"

# Check if updater script exists
if [ ! -f "$UPDATER_SCRIPT" ]; then
    print_error "eden_updater.sh not found in $SCRIPT_DIR"
    exit 1
fi

# ============================================================================
# SYSTEMD TIMER SETUP
# ============================================================================
setup_systemd() {
    print_info "Setting up systemd timer..."
    
    # Create auto-update wrapper script
    cat > "$SCRIPT_DIR/eden_auto_update.sh" << 'EOF'
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
EOF
    
    chmod +x "$SCRIPT_DIR/eden_auto_update.sh"
    
    # Create systemd service file
    mkdir -p ~/.config/systemd/user
    
    cat > ~/.config/systemd/user/eden-updater.service << EOF
[Unit]
Description=Eden Linux Auto-Updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/eden_auto_update.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
    
    # Create systemd timer file
    cat > ~/.config/systemd/user/eden-updater.timer << EOF
[Unit]
Description=Eden Linux Auto-Updater Timer
Requires=eden-updater.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=12h
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Reload systemd and enable timer
    systemctl --user daemon-reload
    systemctl --user enable eden-updater.timer
    systemctl --user start eden-updater.timer
    
    print_success "Systemd timer installed and started!"
    print_info "Timer will run every 12 hours"
    print_info "Logs location: ~/.local/share/eden-updater/auto-update.log"
    echo ""
    print_info "Useful commands:"
    echo "  - Check timer status: systemctl --user status eden-updater.timer"
    echo "  - View timer schedule: systemctl --user list-timers"
    echo "  - Stop timer: systemctl --user stop eden-updater.timer"
    echo "  - Disable timer: systemctl --user disable eden-updater.timer"
    echo "  - Run update now: systemctl --user start eden-updater.service"
    echo "  - View logs: journalctl --user -u eden-updater.service"
}

# ============================================================================
# CRONTAB SETUP
# ============================================================================
setup_crontab() {
    print_info "Setting up crontab..."
    
    # Create auto-update wrapper script (same as systemd)
    cat > "$SCRIPT_DIR/eden_auto_update.sh" << 'EOF'
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
EOF
    
    chmod +x "$SCRIPT_DIR/eden_auto_update.sh"
    
    # Add to crontab (runs every 12 hours at 2am and 2pm)
    CRON_ENTRY="0 2,14 * * * $SCRIPT_DIR/eden_auto_update.sh"
    
    # Check if entry already exists
    if crontab -l 2>/dev/null | grep -q "eden_auto_update.sh"; then
        print_info "Crontab entry already exists. Updating..."
        (crontab -l 2>/dev/null | grep -v "eden_auto_update.sh"; echo "$CRON_ENTRY") | crontab -
    else
        (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    fi
    
    print_success "Crontab entry installed!"
    print_info "Update will run every 12 hours (2am and 2pm)"
    print_info "Logs location: ~/.local/share/eden-updater/auto-update.log"
    echo ""
    print_info "Useful commands:"
    echo "  - View crontab: crontab -l"
    echo "  - Edit crontab: crontab -e"
    echo "  - Remove entry: crontab -e (then delete the eden line)"
    echo "  - View logs: tail -f ~/.local/share/eden-updater/auto-update.log"
}

# ============================================================================
# MAIN MENU
# ============================================================================
main() {
    echo "========================================="
    echo "  Eden Linux Auto-Updater Setup"
    echo "========================================="
    echo ""
    echo "This will set up automatic update checks every 12 hours."
    echo "Updates only run when Eden Linux is not in use."
    echo ""
    echo "Choose installation method:"
    echo "  1) Systemd timer (recommended for modern systems)"
    echo "  2) Crontab (traditional, works everywhere)"
    echo "  3) Cancel"
    echo ""
    read -p "Enter choice [1-3]: " choice
    
    case $choice in
        1)
            setup_systemd
            ;;
        2)
            setup_crontab
            ;;
        3)
            print_info "Setup cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    print_success "Auto-updater setup complete!"
    echo ""
    print_info "The updater will:"
    echo "  ✓ Check for updates every 12 hours"
    echo "  ✓ Only update when Eden Linux is not running"
    echo "  ✓ Automatically download and install new versions"
    echo "  ✓ Keep old versions in ~/Applications_old"
    echo "  ✓ Log all activities to ~/.local/share/eden-updater/auto-update.log"
}

main