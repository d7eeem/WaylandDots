#!/usr/bin/env bash

# Exit on error
set -e

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ]; then
    exit 0
fi

# Detect AUR helper
get_aurhlpr() {
    if command -v yay &> /dev/null; then
        echo "yay"
    elif command -v paru &> /dev/null; then
        echo "paru"
    elif command -v pacaur &> /dev/null; then
        echo "pacaur"
    elif command -v trizen &> /dev/null; then
        echo "trizen"
    else
        echo ""
    fi
}

aurhlpr=$(get_aurhlpr)

# Check if flatpak is installed
pkg_installed() {
    pacman -Qi "$1" &> /dev/null
}

fpk_exup="flatpak update"

# Trigger upgrade
if [ "$1" == "up" ]; then
    trap 'pkill -RTMIN+20 waybar' EXIT
    
    if [ -z "$aurhlpr" ]; then
        echo "Error: No AUR helper found. Please install yay, paru, or another AUR helper." >&2
        exit 1
    fi
    
    command="
    fastfetch
    $0 upgrade
    ${aurhlpr} -Syu --noconfirm || ${aurhlpr} -Syu
    $fpk_exup -y
    echo ''
    echo 'Update complete!'
    read -n 1 -p 'Press any key to continue...'
    "
    kitty --title systemupdate sh -c "${command}"
    exit 0
fi

# Check for AUR updates
aur=0
if [ -n "$aurhlpr" ] && command -v "${aurhlpr}" &> /dev/null; then
    aur=$(${aurhlpr} -Qua 2>/dev/null | wc -l)
fi

# Check for Chaotic-AUR updates
chaotic=0
if grep -q "^\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
    # Get list of packages from chaotic-aur repo
    chaotic_pkgs=$(pacman -Sl chaotic-aur 2>/dev/null | awk '{print $2}')
    
    if [ -n "$chaotic_pkgs" ]; then
        # Check which installed packages are from chaotic-aur and have updates
        for pkg in $chaotic_pkgs; do
            if pacman -Q "$pkg" &>/dev/null; then
                # Check if update is available
                if checkupdates 2>/dev/null | grep -q "^$pkg "; then
                    ((chaotic++))
                fi
            fi
        done
    fi
fi

# Check for official updates with timeout
ofc=0
MAX_WAIT=30  # Maximum seconds to wait for checkupdates
elapsed=0

# Wait for existing checkupdates to finish (with timeout)
while pgrep -x checkupdates > /dev/null && [ $elapsed -lt $MAX_WAIT ]; do
    sleep 1
    ((elapsed++))
done

# Run checkupdates if not timed out
if [ $elapsed -lt $MAX_WAIT ]; then
    ofc=$(checkupdates 2>/dev/null | wc -l)
    # Subtract chaotic-aur updates from official count to avoid double-counting
    ofc=$((ofc - chaotic))
    [ $ofc -lt 0 ] && ofc=0
fi

# Check for flatpak updates
fpk=0
fpk_disp=""
if command -v flatpak &> /dev/null && pkg_installed flatpak; then
    fpk=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
    fpk_disp="\n󰏓 Flatpak $fpk"
fi

# Calculate total available updates
upd=$((ofc + aur + chaotic + fpk))

# Display upgrade summary
if [ "${1}" == "upgrade" ]; then
    printf "\n╭─────────────────────────╮\n"
    printf "│   System Update Check   │\n"
    printf "╰─────────────────────────╯\n\n"
    printf "  📦 Official    : %-3s\n" "$ofc"
    printf "  📦 AUR         : %-3s\n" "$aur"
    printf "  📦 Chaotic-AUR : %-3s\n" "$chaotic"
    printf "  📦 Flatpak     : %-3s\n" "$fpk"
    printf "  ─────────────────────\n"
    printf "  📊 Total       : %-3s\n\n" "$upd"
    exit 0
fi

# Show tooltip for Waybar
if [ $upd -eq 0 ]; then
    upd=""  # Remove icon completely
    # upd="󰮯"  # Uncomment to show icon when no updates
    echo "$upd"
else
    echo "󰮯 $upd"
fi
