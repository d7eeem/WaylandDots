#!/usr/bin/env sh

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"
pkgChk=("io.missioncenter.MissionCenter" "htop" "btop" "top")

for sysMon in "${!pkgChk[@]}"; do
    [ "${sysMon}" -gt 0 ] && term=$(grep -E '^\$term' "${confDir}/hypr/hyprkeys.conf" | cut -d '=' -f2 | xargs)
    if pkg_installed "${pkgChk[sysMon]}" ; then
        pkill -x "${pkgChk[sysMon]}" || ${term} "${pkgChk[sysMon]}" &
        break
    fi
done

