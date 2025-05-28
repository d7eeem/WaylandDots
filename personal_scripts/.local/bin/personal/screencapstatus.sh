#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem


# Check if wf-recorder is running
# wf_recorder_active=$(pgrep -x wf-recorder > /dev/null && echo true || echo false)
#
# # Check for Discord screen sharing via PipeWire nodes
# discord_sharing=$(pactl list 2>/dev/null | rg "node.name = \"discord_capture\"" && echo false || echo true)
#
# if [[ "$wf_recorder_active" == "true" || "$discord_sharing" == "true" ]]; then
#     echo '{"text": "", "tooltip": "Screen recording or sharing active", "class": "recording"}'
# else
#     echo ""
# fi

# Check if wf-recorder is running
wf_recorder_active=false
if pgrep -x wf-recorder > /dev/null; then
    wf_recorder_active=true
fi

# Check if Discord is running (any variant, case-insensitive)
discord_running=false
if pgrep -f -i discord > /dev/null; then
    discord_running=true
fi

# Check for active screen capture node (likely used by Discord)
discord_sharing=false
if [[ "$discord_running" == "true" ]]; then
    if pw-dump | jq -e '.[] |
        select(.type == "PipeWire:Interface:Node") |
        select(.info.props."node.name" | test("xdg-desktop-portal.*")) |
        select(.info.props."media.class" == "Video/Source") |
        select(.info.props."stream.is-live" == true)' > /dev/null; then
        discord_sharing=true
    fi
fi
# Display icon and tooltip if recording or screen sharing is active
if [[ "$wf_recorder_active" == "true" || "$discord_sharing" == "true" ]]; then
    echo '{"text": "", "tooltip": "Screen recording or sharing active", "class": "recording"}'
else
    echo ""
fi
