#!/usr/bin/env bash
[[ ! -f /etc/arch-release ]] && echo '{"text":"","tooltip":"Not Arch Linux"}' && exit 0

aurhlpr="yay"
is_flatpak_installed() { command -v flatpak >/dev/null 2>&1; }
is_chaotic_enabled() { grep -q "^\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; }

get_update_counts() {
    local aur=0
    command -v "$aurhlpr" >/dev/null 2>&1 && aur=$("$aurhlpr" -Qua 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | wc -l)
    
    official_raw=$(checkupdates 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
    local ofc=0 chaotic=0 official_list="" chaotic_list=""
    
    if [[ -n "$official_raw" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            pkg_name=$(echo "$line" | awk '{print $1}')
            if is_chaotic_enabled && pacman -Si "$pkg_name" 2>/dev/null | grep -q "^Repository.*chaotic-aur"; then
                ((chaotic++)); chaotic_list="${chaotic_list}${line}"$'\n'
            else
                ((ofc++)); official_list="${official_list}${line}"$'\n'
            fi
        done <<< "$official_raw"
    fi
    
    local fpk=0
    is_flatpak_installed && fpk=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
    echo "$ofc $chaotic $aur $fpk"
}

if [[ "$1" == "up" ]]; then
    if [[ -n "$TERM" && "$TERM" != "dumb" ]]; then
        fastfetch; bash "$(realpath "$0")" upgrade
        $aurhlpr -Syu; flatpak update -y
        echo ''; echo 'Update complete!'; read -n 1 -p 'Press any key to continue...'
    else
        script_path="$(realpath "$0")"
        terminal="${TERMINAL:-kitty}"
        uwsm-app -- "$terminal" --title="System Update" -e bash -c "
            fastfetch; bash '$script_path' upgrade
            $aurhlpr -Syu; flatpak update -y
            echo ''; echo 'Update complete!'; read -n 1 -p 'Press any key to continue...'
        "
    fi
    pkill -RTMIN+20 waybar; exit 0
fi

if [[ "$1" == "upgrade" ]]; then
    echo ""; echo "╭─────────────────────────╮"; echo "│   System Update Check   │"; echo "╰─────────────────────────╯"; echo ""
    read -r ofc chaotic aur fpk <<< "$(get_update_counts)"
    upd=$((ofc + aur + chaotic + fpk))
    echo "  📦 Official    : $ofc"; echo "  📦 Chaotic-AUR : $chaotic"; echo "  📦 AUR         : $aur"; echo "  📦 Flatpak     : $fpk"
    echo "  ─────────────────────"; echo "  📊 Total       : $upd"; echo ""; exit 0
fi

read -r ofc chaotic aur fpk <<< "$(get_update_counts)"
upd=$((ofc + aur + chaotic + fpk))
[[ $upd -eq 0 ]] && echo '{"text":"","tooltip":"System up to date"}' && exit 0

text="󰮯 $upd"
tooltip=""
official_raw=$(checkupdates 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
official_list="" chaotic_list=""

if [[ -n "$official_raw" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        pkg_name=$(echo "$line" | awk '{print $1}')
        is_chaotic_enabled && pacman -Si "$pkg_name" 2>/dev/null | grep -q "^Repository.*chaotic-aur" && chaotic_list="${chaotic_list}${line}"$'\n' || official_list="${official_list}${line}"$'\n'
    done <<< "$official_raw"
fi

total_packages=$((ofc + chaotic))
if [[ $total_packages -gt 10 ]]; then
    tooltip="Too many updates to display individually"
else
    [[ -n "$official_list" ]] && tooltip="$official_list"
    if [[ $chaotic -gt 0 && -n "$chaotic_list" ]]; then
        [[ -n "$tooltip" ]] && tooltip="${tooltip}"$'\n'
        tooltip="${tooltip}Chaotic-AUR Updates:"$'\n'"${chaotic_list}"
    fi
fi

[[ -n "$tooltip" ]] && tooltip="${tooltip}"$'\n'
tooltip="${tooltip}󱓽 Official $ofc"
[[ $chaotic -gt 0 ]] && tooltip="${tooltip}"$'\n'"󱓾 Chaotic-AUR $chaotic"
tooltip="${tooltip}"$'\n'"󱓾 AUR $aur"
[[ $fpk -gt 0 ]] && tooltip="${tooltip}"$'\n'"󰏓 Flatpak $fpk"

tooltip="${tooltip//\\/\\\\}"; tooltip="${tooltip//\"/\\\"}"; tooltip="${tooltip//$'\n'/\\n}"
echo "{\"text\":\"${text}\", \"tooltip\":\"${tooltip}\"}"; exit 0
