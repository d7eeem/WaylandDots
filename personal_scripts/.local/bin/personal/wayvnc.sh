#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem


# === CONFIG ===
VIRTUAL_WORKSPACE=3
REAL_MONITOR=""
VIRTUAL_MONITOR=""

# === CLEANUP FUNCTION ===
cleanup() {
  printf "\n[wayvnc] Cleaning up...\n"
  
  # Only cleanup if we have a virtual monitor
  if [ -n "$VIRTUAL_MONITOR" ]; then
    # Check if workspace exists before moving
    if hyprctl workspaces -j | jq -e ".[] | select(.id == $VIRTUAL_WORKSPACE)" > /dev/null 2>&1; then
      hyprctl dispatch moveworkspacetomonitor "$VIRTUAL_WORKSPACE" "$REAL_MONITOR" 2>/dev/null
    fi
    hyprctl dispatch focusmonitor "$REAL_MONITOR" 2>/dev/null
  fi
  
  pkill wayvnc 2>/dev/null
  sleep 0.5
  
  # Remove the headless monitor if it exists
  if [ -n "$VIRTUAL_MONITOR" ] && hyprctl monitors | grep -q "$VIRTUAL_MONITOR"; then
    hyprctl output remove "$VIRTUAL_MONITOR"
  fi
  
  printf "[wayvnc] Done.\n"
  exit 0
}

# === Trap Exit for Cleanup ===
trap cleanup INT TERM EXIT

# === Detect the currently focused/active real monitor ===
REAL_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

if [ -z "$REAL_MONITOR" ]; then
  # Fallback: get the first non-headless monitor
  REAL_MONITOR=$(hyprctl monitors -j | jq -r '[.[] | select(.name | contains("HEADLESS") | not)] | .[0].name')
fi

if [ -z "$REAL_MONITOR" ]; then
  printf "[wayvnc] ERROR: No real monitor detected\n"
  exit 1
fi

printf "[wayvnc] Detected real monitor: %s\n" "$REAL_MONITOR"

# === Create headless monitor and detect its name ===
printf "[wayvnc] Creating headless monitor...\n"
hyprctl output create headless
sleep 1.5

# Detect the headless monitor name - get only the newest one
VIRTUAL_MONITOR=$(hyprctl monitors -j | jq -r '[.[] | select(.name | contains("HEADLESS"))] | .[-1].name')

if [ -z "$VIRTUAL_MONITOR" ]; then
  printf "[wayvnc] ERROR: Failed to create or detect headless monitor\n"
  printf "[wayvnc] Available monitors:\n"
  hyprctl monitors
  exit 1
fi

printf "[wayvnc] Detected virtual monitor: %s\n" "$VIRTUAL_MONITOR"

# === Assign workspace and activate it ===
printf "[wayvnc] Setting up workspace %s on %s...\n" "$VIRTUAL_WORKSPACE" "$VIRTUAL_MONITOR"

# Focus the virtual monitor first
hyprctl dispatch focusmonitor "$VIRTUAL_MONITOR"
sleep 0.3

# Switch to workspace (this creates it on the virtual monitor)
hyprctl dispatch workspace "$VIRTUAL_WORKSPACE"
sleep 0.5

# === Return focus to your real monitor ===
hyprctl dispatch focusmonitor "$REAL_MONITOR"
sleep 0.3

# === Start WayVNC ===
printf "[wayvnc] Starting WayVNC on %s...\n" "$VIRTUAL_MONITOR"
wayvnc 0.0.0.0 5900 "$VIRTUAL_MONITOR"
