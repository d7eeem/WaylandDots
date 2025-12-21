#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|

# Check if wf-recorder is running
if pgrep -x wf-recorder >/dev/null || pgrep -f "^gpu-screen-recorder.*-o" >/dev/null; then
  echo '{"text": "   ", "tooltip": "Stop recording", "class": "recording"}'
else
  echo '{"text": "", "tooltip": "", "class": "idle"}'
fi
