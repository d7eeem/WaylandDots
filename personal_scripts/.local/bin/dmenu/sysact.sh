#!/bin/bash

case "$(echo -e "Shutdown\nRestart\nLogout\nSuspend\nLock\nEdit" | dmenu -i -p \
  " ⏻ " -l 6)" in
Shutdown) exec systemctl poweroff ;;
Restart) exec systemctl reboot ;;
Logout) logout.sh ;;
Suspend) systemctl suspend && betterlockscreen -l dimblur ;;
Lock) exec "$HOME/.local/bin/hyper/lock.sh" ;;
# Lock)  slock;;
Edit) $TERMINAL -e nvim "$0" & ;;
esac

# -nb "${COLOR_BACKGROUND:-#32302F}" \
#     -nf "${COLOR_DEFAULT:-#cc5e50}" \
#     -sf "${COLOR_HIGHLIGHT:-#fff}" \
#     -sb "#cc5e50" \
