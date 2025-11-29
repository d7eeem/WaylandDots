#!/usr/bin/env bash

set -euo pipefail

baseDir=$(dirname "$(realpath "$0")")
scrDir=$(dirname "$(realpath "$0")")

# Load global functions if available
if ! source "${scrDir}/global_fn.sh" 2>/dev/null; then
    echo "Warning: unable to source global_fn.sh, continuing..."
fi

# Check if flatpak is installed
if ! command -v flatpak &>/dev/null; then
    echo "Installing flatpak..."
    sudo pacman -S --noconfirm flatpak
fi

# Add Flathub remote if missing
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Parse custom_flat.lst (ignore comments and empty lines)
mapfile -t flats < <(
    awk -F '#' '{print $1}' "${baseDir}/custom_flat.lst" | sed 's/ //g' | grep -v '^$'
)

# Install listed flatpaks if any
if [ ${#flats[@]} -gt 0 ]; then
    flatpak install --user -y flathub "${flats[@]}"
else
    echo "No flatpaks listed in custom_flat.lst"
fi

# Clean unused packages and update
flatpak remove --unused -y
flatpak update -y

# Detect current GTK theme & icons (fallback to Adwaita)
gtkTheme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | sed "s/'//g" || echo "Adwaita")
gtkIcon=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | sed "s/'//g" || echo "Adwaita")

# Apply overrides in one call
flatpak --user override \
    --filesystem=~/.themes \
    --filesystem=~/.icons \
    --env=GTK_THEME="${gtkTheme}" \
    --env=ICON_THEME="${gtkIcon}"

echo "Flatpak setup complete ✅"


#
# baseDir=$(dirname "$(realpath "$0")")
# scrDir=$(dirname "$(realpath "$0")")
#
#
# source "${scrDir}/global_fn.sh"
# if [ $? -ne 0 ]; then
#     echo "Error: unable to source global_fn.sh..."
#     exit 1
# fi
#
# if ! pkg_installed flatpak; then
#     sudo pacman -S flatpak
# fi
#
# flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# flats=$(awk -F '#' '{print $1}' "${baseDir}/custom_flat.lst" | sed 's/ //g' | xargs)
#
# flatpak install --user -y flathub "${flats}"
# flatpak remove --unused
#
# gtkTheme=$(gsettings get org.gnome.desktop.interface gtk-theme | sed "s/'//g")
# gtkIcon=$(gsettings get org.gnome.desktop.interface icon-theme | sed "s/'//g")
#
# flatpak --user override --filesystem=~/.themes
# flatpak --user override --filesystem=~/.icons
#
# flatpak --user override --env=GTK_THEME="${gtkTheme}"
# flatpak --user override --env=ICON_THEME="${gtkIcon}"
