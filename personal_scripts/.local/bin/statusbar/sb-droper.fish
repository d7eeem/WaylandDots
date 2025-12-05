#!/usr/bin/env fish

# Define menu entries
set options \
  Zen \
  Steam \
  Files \
  Brave \
  Theme \
  anymex\
  Discord \
  Vesktop \
  Jellyfin \
  "Heroic Games Launcher"

# Use Rofi to select
#set choice (printf '%s\n' $options | rofi -dmenu -p "Launch App" -theme $HOME/.config/rofi/clipboard.rasi )
set choice (printf '%s\n' $options | rofi -dmenu -p "Launch App" -theme $HOME/.config/rofi/clipboard/clipboard.rasi )

# Launch based on selection
switch $choice
    case "Discord"
        uwsm app -a discord -- discord &

    case "Jellyfin"
        uwsm app -a delfin -- flatpak run cafe.avery.Delfin &

    case "Vesktop"
        uwsm app -a vesktop -- vesktop &

    case "Steam"
        uwsm app -a steam -- steam &

    case "Heroic Games Launcher"
        uwsm app -a heroic -- heroic &

    case "Files"
        uwsm app -a nautilus -- nautilus &

    case "Zen"
        uwsm app -a zen -- zen.fish &

    case "Brave"
        uwsm app -a brave -- brave.fish &

    case "Theme"
        uwsm app -a setwall -- $HOME/.local/bin/personal/setwall.sh &

    case "anymex"
        uwsm app -a anymex -- $HOME/AppImages/anymex.appimage &

    case '*'
        exit 1
end
