#!/usr/bin/env fish

# Check if running Arch Linux
if not test -f /etc/arch-release
    exit 0
end

# Set AUR helper (you can change this to your preferred AUR helper)
# Common AUR helpers: yay, paru, pacaur, trizen
set aurhlpr "yay"

# Check if flatpak is installed
function is_flatpak_installed
    command -v flatpak >/dev/null 2>&1
end

set fpk_exup "flatpak update"

# Trigger upgrade
if test "$argv[1]" = "up"
    trap 'pkill -RTMIN+20 waybar' EXIT
    set script_path (realpath (status -f))
    set command "
        fastfetch
        fish $script_path upgrade
        $aurhlpr -Syu
        $fpk_exup
        read -n 1 -p 'Press any key to continue...'
        "
    kitty --title="System Update" sh -c "$command"
end

# Check for AUR updates (strip colors)
set aur (count ($aurhlpr -Qua 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'))
set ofc (count (checkupdates | sed 's/\x1b\[[0-9;]*m//g'))

# Check for flatpak updates
if is_flatpak_installed
    set fpk (count (flatpak remote-ls --updates 2>/dev/null))
    set fpk_disp "$fpk"
else
    set fpk 0
    set fpk_disp ""
end

# Calculate total available updates
set upd (math $ofc + $aur + $fpk)

# Exit early if no updates available
if test $upd -eq 0
    exit 0
end

if test "$argv[1]" = "upgrade"
    printf "[Official] %-10s\n[AUR]      %-10s\n[Flatpak]  %-10s\n" $ofc $aur $fpk
    exit 0
end

# Get detailed update information (strip colors)
set output (checkupdates | sed 's/\x1b\[[0-9;]*m//g')
set number (count $output)
set text "󰮯 $upd"

# Format tooltip based on number of updates
if test $number -gt 10
    # Just show the count for more than 10 updates
    set tooltip ""
else
    # Show package names for 10 or fewer updates
    set tooltip (string join '\n' $output)
end

# Add update counts to tooltip
set tooltip "$tooltip\n󱓽 Official $ofc\n󱓾 AUR $aur\n󰏓 Flatpak $fpk_disp"

# Output JSON
echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
exit 0 
