#!/usr/bin/env bash

# Only run on Arch-based systems
if [ ! -f /etc/arch-release ]; then
  exit 0
fi

# Determine AUR helper
aurhlpr=""
if command -v yay &> /dev/null; then
    aurhlpr="yay"
elif command -v paru &> /dev/null; then
    aurhlpr="paru"
fi

# Flatpak update command
fpk_exup="flatpak update"

# Trigger upgrade in a terminal
if [ "$1" == "up" ]; then
    trap 'pkill -RTMIN+20 waybar' EXIT
    command="
        fastfetch
        $0 upgrade
        ${aurhlpr} -Syu
        $fpk_exup
        read -n 1 -p 'Press any key to continue...'
    "
    kitty --title systemupdate sh -c "${command}"
    exit
fi

# Check for AUR updates
aur=0
if [ -n "$aurhlpr" ]; then
    aur=$($aurhlpr -Qua | wc -l)
fi

# Check for official repo updates
ofc=0
if command -v checkupdates &> /dev/null; then
    # Wait for any running checkupdates to finish
    while pgrep -x checkupdates >/dev/null; do sleep 1; done
    ofc=$(checkupdates | wc -l)
fi

# Check for Flatpak updates
fpk=0
fpk_disp=""
if command -v flatpak &> /dev/null; then
    fpk=$(flatpak remote-ls --updates | wc -l)
    fpk_disp="\n󰏓 Flatpak $fpk"
fi

# Total updates
upd=$((ofc + aur + fpk))

# Show detailed list if upgrading
if [ "${1}" == upgrade ]; then
    printf "[Official] %-10s\n[AUR]      %-10s\n[Flatpak]  %-10s\n" "$ofc" "$aur" "$fpk"
    exit
fi

# Show tooltip JSON for Waybar
if [ $upd -eq 0 ]; then
    echo "{\"text\":\"\", \"tooltip\":\" Packages are up to date\"}"
else
    echo "{\"text\":\"󰮯 $upd\", \"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur$fpk_disp\"}"
fi

