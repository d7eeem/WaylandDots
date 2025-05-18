#!/bin/bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem




set -euo pipefail
# Paths
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

waybar_dir="${confDir}/waybar"
modules_dir="$waybar_dir/modules"
conf_file="$waybar_dir/config.jsonc"
conf_ctl="$waybar_dir/config.ctl"

# Get active config line
active_line="$(grep '^1|' "$conf_ctl")"
[[ -z "$active_line" ]] && { echo "❌ No active config in config.ctl"; exit 1; }

# Parse fields
IFS='|' read -r _ height position mod_left mod_center mod_right <<< "$active_line"

# Fallback: calculate height from monitor if unset
if [[ -z "$height" ]]; then
    height=$(hyprctl -j monitors | jq '.[] | select(.focused == true) | (.height / .scale * 0.02 | floor)')
    height="${height:-32}"
fi
export w_height="$height"

# Size calculations
export i_size=$(( w_height * 6 / 10 < 12 ? 12 : w_height * 6 / 10 ))
export i_task=$(( w_height * 6 / 10 < 16 ? 16 : w_height * 6 / 10 ))
export i_priv=$(( w_height * 6 / 13 < 12 ? 12 : w_height * 6 / 13 ))

# Waybar output
if [[ -n "${WAYBAR_OUTPUT[*]:-}" ]]; then
    w_output=$(printf '"%s", ' "${WAYBAR_OUTPUT[@]}")
    export w_output="${w_output%, }"
else
    export w_output='"*"'
fi

# Waybar position
case "$position" in
    left)  export hv_pos="width";  export r_deg=90  ;;
    right) export hv_pos="width";  export r_deg=270 ;;
    *)     export hv_pos="height"; export r_deg=0   ;;
esac
export w_position="$position"

# Generate header
envsubst < "${modules_dir}/header.jsonc" > "$conf_file"

# Convert modules string to JSON array
to_json_array() {
    local raw="$1"

    raw="${raw//(/custom\/l_end}"
    raw="${raw//)/custom\/r_end}"
    raw="${raw//[/"custom/sl_end"}"
    raw="${raw//]/"custom/sr_end"}"
    raw="${raw//\{/"custom/rl_end"}"
    raw="${raw//\}/"custom/rr_end"}"

    IFS=' ' read -ra mods <<< "$raw"
    printf '"%s",' "${mods[@]}" | sed 's/,$//'
}

# Append layout to config
{
    echo -e "\n// Layout from config.ctl"
    echo -e "\t\"modules-left\":   [$(to_json_array "$mod_left")],"
    echo -e "\t\"modules-center\": [$(to_json_array "$mod_center")],"
    echo -e "\t\"modules-right\":  [$(to_json_array "$mod_right")],"
} >> "$conf_file"

# Append module definitions
{
    echo -e "\n// Modules sourced from .ctl"
    echo "$mod_left $mod_center $mod_right" | tr ' ' '\n' | sed 's/##.*//' | sort -u | while read -r mod; do
        [[ -f "${modules_dir}/${mod}.jsonc" ]] && envsubst < "${modules_dir}/${mod}.jsonc"
    done
    cat "${modules_dir}/footer.jsonc"
} >> "$conf_file"

# Generate CSS
"$scrDir/wbarstylegen.sh"

# Restart Waybar
killall waybar 2>/dev/null || true
waybar --config "$conf_file" --style "$waybar_dir/style.css" & disown
