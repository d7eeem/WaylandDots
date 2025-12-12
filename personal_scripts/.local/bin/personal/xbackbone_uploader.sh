#!/bin/bash
if [ -f ~/.env ]; then
  export $(grep -v '^#' ~/.env | xargs)
fi

upload() {
  RESPONSE="$(curl -s -F "token=$XBACK_BONE" -F "upload=@${1}" "${XXBACKBONE_URL}")"

  if [[ "$(echo "${RESPONSE}" | jq -r '.message')" == "OK" ]]; then
    URL="$(echo "${RESPONSE}" | jq -r '.url')"

    if [ "${DESKTOP_SESSION}" != "" ]; then
      echo "${URL}" | wl-copy

      # Send clickable notification with action
      notify-send -a "XBackBone Upload" -u normal \
        "Upload completed" \
        "${URL}" \
        --action="default=Open in Browser" | while read action; do
        if [ "$action" = "default" ]; then
          # Try different browser launchers
          if command -v xdg-open &>/dev/null; then
            xdg-open "$URL" &
          elif command -v open &>/dev/null; then
            open "$URL" &
          elif command -v firefox &>/dev/null; then
            firefox "$URL" &
          elif command -v chromium &>/dev/null; then
            chromium "$URL" &
          fi
        fi
      done &
    else
      echo "${URL}"
    fi
    exit 0
  else
    MESSAGE="$(echo "${RESPONSE}" | jq -r '.message')"
    if [ $? -ne 0 ]; then
      echo "Unexpected response:"
      echo "${RESPONSE}"
      exit 1
    fi

    if [ "${DESKTOP_SESSION}" != "" ]; then
      notify-send -a "XBackBone Upload" -u critical "Error!" "${MESSAGE}"
    else
      echo "Error! ${MESSAGE}"
    fi
    exit 1
  fi
}

check() {
  ERRORS=0

  if [ ! -x "$(command -v jq)" ]; then
    echo "jq command not found."
    ERRORS=1
  fi

  if [ ! -x "$(command -v curl)" ]; then
    echo "curl command not found."
    ERRORS=1
  fi

  if [ ! -x "$(command -v wl-copy)" ] && [ "${DESKTOP_SESSION}" != "" ]; then
    echo "wl-copy command not found."
    ERRORS=1
  fi

  if [ ! -x "$(command -v notify-send)" ] && [ "${DESKTOP_SESSION}" != "" ]; then
    echo "notify-send command not found."
    ERRORS=1
  fi

  if [ "${ERRORS}" -eq 1 ]; then
    exit 1
  fi
}

# Run dependency check
check

if [ -f "${1}" ]; then
  upload "${1}"
else
  if [ "${DESKTOP_SESSION}" != "" ]; then
    notify-send -a "XBackBone Upload" -u critical "Error!" "File specified does not exist."
    exit 1
  else
    echo "Error! File specified does not exist."
    exit 1
  fi
fi
