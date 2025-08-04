#!/usr/bin/env fish

# Define menu entries
set options \
  Zen \
  Steam \
  Files \
  Brave \
  Theme \
  Discord \
  Vesktop \
  Jellyfin \
  "Heroic Games Launcher"

# Use Rofi to select
#set choice (printf '%s\n' $options | rofi -dmenu -p "Launch App" -theme /home/tinker/.config/rofi/clipboard.rasi )
set choice (printf '%s\n' $options | rofi -dmenu -p "Launch App" -theme /home/tinker/.config/rofi/clipboard/clipboard.rasi )

# Launch based on selection
switch $choice
    case "Discord"
        nohup discord >/dev/null 2>&1 &

    case "Jellyfin"
        nohup flatpak run moe.tsuna.tsukimi  >/dev/null 2>&1 &

    case "Vesktop"
        nohup vesktop >/dev/null 2>&1 &

    case "Steam"
        nohup steam >/dev/null 2>&1 &

    case "Heroic Games Launcher"
        nohup heroic >/dev/null 2>&1 &

    case "Files"
        nohup nautilus >/dev/null 2>&1 &

    case "Zen"
        nohup zen-browser >/dev/null 2>&1 &

    case "Brave"
        nohup brave >/dev/null 2>&1 &

    case "Theme"
        nohup /home/tinker/.local/bin/theme_engine/theme_switcher.sh >/dev/null 2>&1 &

    case '*'
        exit 1
end

