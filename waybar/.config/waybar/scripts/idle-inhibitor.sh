#!/bin/bash

PID_FILE="/tmp/idle-inhibitor.pid"
TIME_FILE="/tmp/idle-inhibitor-time"
DURATION_FILE="/tmp/idle-inhibitor-duration"

get_status() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "active"
  else
    echo "inactive"
  fi
}

stop_inhibitor() {
  if [ -f "$PID_FILE" ]; then
    kill $(cat "$PID_FILE") 2>/dev/null
    rm -f "$PID_FILE" "$TIME_FILE" "$DURATION_FILE"
  fi
}

start_inhibitor() {
  local duration=$1

  if [ -n "$duration" ]; then
    # Start with duration
    (
      systemd-inhibit --what=idle --who="Waybar" --why="User requested ($duration min)" --mode=block sleep "${duration}m"
      # Auto cleanup after duration
      rm -f "$PID_FILE" "$TIME_FILE" "$DURATION_FILE"
    ) &
    echo $! >"$PID_FILE"
    echo "$duration" >"$DURATION_FILE"
  else
    # Start indefinitely
    systemd-inhibit --what=idle --who="Waybar" --why="User requested" --mode=block sleep infinity &
    echo $! >"$PID_FILE"
  fi

  date +%s >"$TIME_FILE"
}

toggle() {
  if [ "$(get_status)" = "active" ]; then
    stop_inhibitor
  else
    # Default: start indefinitely (right-click for duration menu)
    start_inhibitor
  fi
}

set_duration() {
  local duration=$1
  stop_inhibitor
  start_inhibitor "$duration"
}

get_time_active() {
  if [ -f "$TIME_FILE" ] && [ "$(get_status)" = "active" ]; then
    start_time=$(cat "$TIME_FILE")
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    hours=$((elapsed / 3600))
    minutes=$(((elapsed % 3600) / 60))

    if [ $hours -gt 0 ]; then
      echo "${hours}h ${minutes}m"
    else
      echo "${minutes}m"
    fi
  else
    echo ""
  fi
}

get_remaining_time() {
  if [ -f "$DURATION_FILE" ] && [ -f "$TIME_FILE" ] && [ "$(get_status)" = "active" ]; then
    duration=$(cat "$DURATION_FILE")
    start_time=$(cat "$TIME_FILE")
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    total_seconds=$((duration * 60))
    remaining=$((total_seconds - elapsed))

    if [ $remaining -gt 0 ]; then
      minutes=$((remaining / 60))
      echo "${minutes}m"
    else
      echo "0m"
    fi
  else
    echo ""
  fi
}

output_waybar() {
  status=$(get_status)
  time_active=$(get_time_active)
  remaining=$(get_remaining_time)

  if [ "$status" = "active" ]; then
    if [ -n "$remaining" ]; then
      tooltip="Idle inhibitor active for $time_active ($remaining remaining)"
      text="-$remaining"
    elif [ -n "$time_active" ]; then
      tooltip="Idle inhibitor active for $time_active"
      text="󰅶"
    else
      tooltip="Idle inhibitor active"
      text="󰅶"
    fi
    printf '{"text":"%s","tooltip":"%s","class":"active"}\n' "$text" "$tooltip"
  else
    printf '{"text":"󰛊","tooltip":"Idle inhibitor inactive","class":"inactive"}\n'
  fi
}

# echo '{"text":"󰅶","tooltip":"'"$tooltip"'","class":"active"}'
case "$1" in
toggle)
  toggle
  ;;
status)
  output_waybar
  ;;
duration)
  set_duration "$2"
  ;;
*)
  output_waybar
  ;;
esac
