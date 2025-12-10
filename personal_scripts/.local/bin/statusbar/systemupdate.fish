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

# Check if Chaotic-AUR is enabled
function is_chaotic_enabled
    grep -q "^\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null
end

set fpk_exup "flatpak update"

# Trigger upgrade
if test "$argv[1]" = "up"
    set script_path (realpath (status -f))
    set command "
        fastfetch
        fish $script_path upgrade
        $aurhlpr -Syu
        $fpk_exup -y
        echo ''
        echo 'Update complete!'
        read -n 1 -p 'echo -n \"Press any key to continue...\"'
        "
    kitty --title="System Update" sh -c "$command"
    # Signal waybar to refresh
    pkill -RTMIN+20 waybar
    exit 0
end

# Check for AUR updates (strip colors)
set aur 0
if command -v $aurhlpr >/dev/null 2>&1
    set aur (count ($aurhlpr -Qua 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'))
end

# Get all official updates
set all_updates (checkupdates 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
set ofc (count $all_updates)
set chaotic 0

# Separate Chaotic-AUR updates from official updates
if is_chaotic_enabled
    set chaotic_updates ""
    set official_updates ""
    
    for update in $all_updates
        set pkg_name (echo $update | awk '{print $1}')
        # Check if package is from chaotic-aur repository
        if pacman -Si $pkg_name 2>/dev/null | grep -q "^Repository.*chaotic-aur"
            set chaotic_updates $chaotic_updates $update
            set chaotic (math $chaotic + 1)
        else
            set official_updates $official_updates $update
        end
    end
    
    # Update counts
    set ofc (math $ofc - $chaotic)
    test $ofc -lt 0; and set ofc 0
    
    # Use separated lists for display
    set all_updates $official_updates
end

# Check for flatpak updates
set fpk 0
set fpk_disp ""
if is_flatpak_installed
    set fpk (count (flatpak remote-ls --updates 2>/dev/null))
    set fpk_disp "$fpk"
end

# Calculate total available updates
set upd (math $ofc + $aur + $chaotic + $fpk)

# Exit early if no updates available
if test $upd -eq 0
    echo ""
    exit 0
end

# Display upgrade summary
if test "$argv[1]" = "upgrade"
    printf "\n╭─────────────────────────╮\n"
    printf "│   System Update Check   │\n"
    printf "╰─────────────────────────╯\n\n"
    printf "  📦 Official    : %-3s\n" $ofc
    printf "  📦 Chaotic-AUR : %-3s\n" $chaotic
    printf "  📦 AUR         : %-3s\n" $aur
    printf "  📦 Flatpak     : %-3s\n" $fpk
    printf "  ─────────────────────\n"
    printf "  📊 Total       : %-3s\n\n" $upd
    exit 0
end

# Get detailed update information
set number (count $all_updates)
set text "󰮯 $upd"

# Format tooltip based on number of updates
if test $number -gt 10
    # Just show summary for more than 10 updates
    set tooltip "Too many updates to display individually"
else if test $number -gt 0
    # Show package names for 10 or fewer updates
    set tooltip (string join '\n' $all_updates)
else
    set tooltip ""
end

# Add Chaotic-AUR updates to tooltip if applicable
if test $chaotic -gt 0
    if test $number -le 10
        set tooltip "$tooltip\n\nChaotic-AUR Updates:\n"(string join '\n' $chaotic_updates)
    end
end

# Add update counts to tooltip
if test -n "$tooltip"
    set tooltip "$tooltip\n"
end
set tooltip "$tooltip\n󱓽 Official $ofc"
if test $chaotic -gt 0
    set tooltip "$tooltip\n󱓾 Chaotic-AUR $chaotic"
end
set tooltip "$tooltip\n󱓾 AUR $aur"
if test $fpk -gt 0
    set tooltip "$tooltip\n󰏓 Flatpak $fpk"
end

# Output JSON
echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
exit 0
