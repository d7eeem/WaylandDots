#!/usr/bin/env bash

# Check if running Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    echo '{"text":"","tooltip":"Not Arch Linux"}'
    exit 0
fi

# Set AUR helper
aurhlpr="yay"

# Check if flatpak is installed
is_flatpak_installed() {
    command -v flatpak >/dev/null 2>&1
}

# Check if Chaotic-AUR is enabled
is_chaotic_enabled() {
    grep -q "^\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null
}

# Trigger upgrade
if [[ "$1" == "up" ]]; then
    script_path="$(realpath "$0")"
    terminal="${TERMINAL:-kitty}"
    uwsm-app -- "$terminal" --title="System Update" -e bash -c "
        fastfetch
        bash '$script_path' upgrade
        $aurhlpr -Syu
        flatpak update -y
        echo ''
        echo 'Update complete!'
        read -n 1 -p 'Press any key to continue...'
    "
    # Signal waybar to refresh
    pkill -RTMIN+20 waybar
    exit 0
fi

# Check for AUR updates (strip colors)
aur=0
if command -v "$aurhlpr" >/dev/null 2>&1; then
    aur_count=$("$aurhlpr" -Qua 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | wc -l)
    aur=${aur_count:-0}
fi

# Get all official updates
official_raw=$(checkupdates 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
ofc=0
chaotic=0
official_list=""
chaotic_list=""

if [[ -n "$official_raw" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        pkg_name=$(echo "$line" | awk '{print $1}')
        
        # Check if package is from chaotic-aur repository
        if is_chaotic_enabled && pacman -Si "$pkg_name" 2>/dev/null | grep -q "^Repository.*chaotic-aur"; then
            chaotic=$((chaotic + 1))
            chaotic_list="${chaotic_list}${line}"$'\n'
        else
            ofc=$((ofc + 1))
            official_list="${official_list}${line}"$'\n'
        fi
    done <<< "$official_raw"
fi

# Check for flatpak updates
fpk=0
if is_flatpak_installed; then
    fpk_count=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
    fpk=${fpk_count:-0}
fi

# Calculate total available updates
upd=$((ofc + aur + chaotic + fpk))

# Display upgrade summary
if [[ "$1" == "upgrade" ]]; then
    echo ""
    echo "╭─────────────────────────╮"
    echo "│   System Update Check   │"
    echo "╰─────────────────────────╯"
    echo ""
    echo "  📦 Official    : $ofc"
    echo "  📦 Chaotic-AUR : $chaotic"
    echo "  📦 AUR         : $aur"
    echo "  📦 Flatpak     : $fpk"
    echo "  ─────────────────────"
    echo "  📊 Total       : $upd"
    echo ""
    exit 0
fi

# Always output something for waybar (even if no updates)
if [[ $upd -eq 0 ]]; then
    echo '{"text":"","tooltip":"System up to date"}'
    exit 0
fi

# Build the text
text="󰮯 $upd"

# Build tooltip
tooltip=""

# Add package details if 10 or fewer
total_packages=$((ofc + chaotic))
if [[ $total_packages -gt 10 ]]; then
    tooltip="Too many updates to display individually"
else
    # Add official updates
    if [[ -n "$official_list" ]]; then
        tooltip="$official_list"
    fi
    
    # Add chaotic updates
    if [[ $chaotic -gt 0 && -n "$chaotic_list" ]]; then
        [[ -n "$tooltip" ]] && tooltip="${tooltip}"$'\n'
        tooltip="${tooltip}Chaotic-AUR Updates:"$'\n'"${chaotic_list}"
    fi
fi

# Add summary counts
[[ -n "$tooltip" ]] && tooltip="${tooltip}"$'\n'
tooltip="${tooltip}󱓽 Official $ofc"
[[ $chaotic -gt 0 ]] && tooltip="${tooltip}"$'\n'"󱓾 Chaotic-AUR $chaotic"
tooltip="${tooltip}"$'\n'"󱓾 AUR $aur"
[[ $fpk -gt 0 ]] && tooltip="${tooltip}"$'\n'"󰏓 Flatpak $fpk"

# Escape for JSON: backslashes first, then quotes, then newlines
tooltip="${tooltip//\\/\\\\}"
tooltip="${tooltip//\"/\\\"}"
tooltip="${tooltip//$'\n'/\\n}"

# Output JSON using echo only
json_output="{\"text\":\"${text}\", \"tooltip\":\"${tooltip}\"}"
echo "$json_output"
exit 0
