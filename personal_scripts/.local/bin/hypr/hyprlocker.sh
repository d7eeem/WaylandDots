#!/bin/bash

# Positions
lockedX=3000
lockedY=1130

defaultX=2560
defaultY=360

# Monitor JSON
monitors=$(hyprctl -j monitors)

# Get current DP-2 position
dp2=$(echo "$monitors" | jq -c '.[] | select(.name == "HDMI-A-1")')
dp2x=$(echo "$dp2" | jq -r '.x')
dp2y=$(echo "$dp2" | jq -r '.y')

# Determine if locked
if [ "$dp2x" -eq "$defaultX" ] && [ "$dp2y" -eq "$defaultY" ]; then
    # Lock
    newX=$lockedX
    newY=$lockedY
    notify-send "🎮 Gaming Mode" "DP-2 locked"
else
    # Unlock
    newX=$defaultX
    newY=$defaultY
    notify-send "🖥️ Normal Mode" "DP-2 restored"
fi

# Apply layout
hyprctl keyword monitor "DP-2,2560x1440@239.96,0x0,1.0"
hyprctl keyword monitor "HDMI-A-1,2560x1080@59.98,${newX}x${newY},1.0"




# #!/bin/bash
#
# # Arrays for unlocked and locked positions
# unlockedMonitorYPositions=(0 0)
# lockedMonitorYPositions=(1152 1550)
#
# # Fetch monitor details from hyprctl
# monitors=$(hyprctl -j monitors)
# tailMonitorIndex=$(($(echo "$monitors" | jq length) - 1))
# monitorIndices=$(seq 0 $tailMonitorIndex)
#
# # Function to validate the arrays for monitor positions
# validatePositions() {
#     local positionArrayName=$1
#     local positionArray=("${!2}") # Indirect expansion
#     local monitorCount=$(echo "$monitors" | jq length)
#
#     if [ ${#positionArray[@]} -ne $monitorCount ]; then
#         notify-send "Hyprlock Error" "${positionArrayName} array size (${#positionArray[@]}) does not match the number of monitors ($monitorCount)."
#         exit 3
#     fi
# }
#
# # Validate the position arrays
# validatePositions "unlockedMonitorYPositions" unlockedMonitorYPositions[@]
# validatePositions "lockedMonitorYPositions" lockedMonitorYPositions[@]
#
# # Main logic
# if [ "$1" == "" ]; then
#     monitorUnlocked=0
#     for monitorIndex in $monitorIndices; do
#         monitor=$(echo "$monitors" | jq -c ".[$monitorIndex]")
#         unlockedMonitorYPosition=${unlockedMonitorYPositions[$monitorIndex]}
#
#         # If already in the unlocked position, skip
#         if [ $(echo "$monitor" | jq -j ".y") -eq $unlockedMonitorYPosition ]; then
#             continue
#         fi
#
#         hyprctl keyword monitor $(echo "$monitor" | jq -j ".name"),$(echo "$monitor" | jq -j ".width")x$(echo "$monitor" | jq -j ".height")@$(echo "$monitor" | jq -j ".refreshRate"),$(echo "$monitor" | jq -j ".x")x$unlockedMonitorYPosition,$(echo "$monitor" | jq -j ".scale") > /dev/null
#         monitorUnlocked=1
#         notify-send "Hyprlock" "Unlocked monitor $monitorIndex"
#     done
#
#     if [ $monitorUnlocked -eq 1 ]; then exit; fi
#
#     # Lock the focused monitor
#     for monitorIndex in $monitorIndices; do
#         monitor=$(echo "$monitors" | jq -c ".[$monitorIndex]")
#         if [ $(echo "$monitor" | jq -j ".focused") == "false" ]; then
#             continue
#         fi
#
#         hyprctl keyword monitor $(echo "$monitor" | jq -j ".name"),$(echo "$monitor" | jq -j ".width")x$(echo "$monitor" | jq -j ".height")@$(echo "$monitor" | jq -j ".refreshRate"),$(echo "$monitor" | jq -j ".x")x${lockedMonitorYPositions[$monitorIndex]},$(echo "$monitor" | jq -j ".scale") > /dev/null
#         notify-send "Hyprlock" "Locked monitor $monitorIndex"
#         exit
#     done
#
# elif [ "$1" == "status" ]; then
#     for monitorIndex in $monitorIndices; do
#         if [ $(echo "$monitors" | jq -j ".[$monitorIndex].y") -eq ${unlockedMonitorYPositions[$monitorIndex]} ]; then
#             notify-send "Hyprlock Status" "Monitor $monitorIndex: Unlocked"
#         else
#             notify-send "Hyprlock Status" "Monitor $monitorIndex: Locked"
#         fi
#     done
#     exit
#
# elif [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
#     notify-send "Hyprlock Help" "Usage:\n  hyprlock status\n  hyprlock [monitor_id]"
#     exit
# fi
#
# # Validate the monitor_id argument
# if ! [[ $1 =~ ^[0-9]+$ ]]; then
#     notify-send "Hyprlock Error" "Invalid parameter. [monitor_id] must be an integer."
#     exit 1
# fi
#
# if [ $1 -lt 0 ] || [ $tailMonitorIndex -lt $1 ]; then
#     notify-send "Hyprlock Error" "Invalid [monitor_id]. Must be between 0 and $tailMonitorIndex."
#     exit 2
# fi
#
# # Lock or unlock a specific monitor
# monitor=$(echo "$monitors" | jq -c ".[$1]")
# unlockedMonitorYPosition=${unlockedMonitorYPositions[$1]}
#
# if [ $(echo "$monitor" | jq -j ".y") -eq $unlockedMonitorYPosition ]; then
#     hyprctl keyword monitor $(echo "$monitor" | jq -j ".name"),$(echo "$monitor" | jq -j ".width")x$(echo "$monitor" | jq -j ".height")@$(echo "$monitor" | jq -j ".refreshRate"),$(echo "$monitor" | jq -j ".x")x${lockedMonitorYPositions[$1]},$(echo "$monitor" | jq -j ".scale") > /dev/null
#     notify-send "Hyprlock" "Locked monitor $1"
# else
#     hyprctl keyword monitor $(echo "$monitor" | jq -j ".name"),$(echo "$monitor" | jq -j ".width")x$(echo "$monitor" | jq -j ".height")@$(echo "$monitor" | jq -j ".refreshRate"),$(echo "$monitor" | jq -j ".x")x$unlockedMonitorYPosition,$(echo "$monitor" | jq -j ".scale") > /dev/null
#     notify-send "Hyprlock" "Unlocked monitor $1"
# fi

#
