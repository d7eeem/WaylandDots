#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|

# Check if wf-recorder is running
wf_recorder_active=false
if pgrep -x wf-recorder >/dev/null; then
  wf_recorder_active=true
fi


if pgrep -x wf-recorder >/dev/null; then
  echo '{"text": "   ", "tooltip": "Screen recording (wf-recorder)", "class": "recording"}'
else
  echo '{"text": "", "tooltip": "", "class": "idle"}'
fi
