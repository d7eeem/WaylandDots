#!/bin/env bash
arch=(
  ffmpeg
  ffmpegthumbnailer
  ttf-liberation
  bc
  yad
  dosfstools
  libnotify
  dunst
  gnome-keyring
  neovim
  mpd
  mpc
  mpv
  noto-fonts-emoji
  ntfs-3g
  network-manager-applet
  ripgrep
  maim
  unrar
  unzip
  p7zip
  liquidctl
  wl-clipboard
  zathura
  zathura-pdf-mupdf
  poppler
  mediainfo
  fzf
  highlight
  stow
  tmux
  lutris
  #wine-staging
  winetricks
  #vkd3d
  #lib32-vkd3d
  #ttf-hack-nerd
  steam
  lf
  lib32-mesa
  vulkan-radeon
  lib32-vulkan-radeon
  libva-mesa-driver
  lib32-libva-mesa-driver
  mesa-vdpau
  lib32-mesa-vdpau
  gamescope
  mangohud
  flatpak
  pavucontrol
  blueman
  bluez
  bluez-utils
  nfs-utils
  qt5ct
  qt6ct
)
aur=(
  pacseek-bin
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
  zathura-cb
  downgrade
  jq
  wdisplays
  kvantum
  #ttf-jetbrains-mono-nerd
  bat
  eza
  #heroic-games-launcher-bin
  yamllint
  shellcheck
  dxvk-bin
  proton
  protontricks
  bottles
  #protonup-qt-bin
  goverlay
  vkbasalt
  lib32-vkbasalt
)

hyper=(
  nwg-look
  sway-audio-idle-inhibit-git
  swayidle
  waybar
  swww
  hyprshot
)
# flatpak=(
#   md.obsidian.Obsidian
#   com.github.tchx84.Flatseal
#   net.davidotek.pupgui2
#   it.mijorus.gearlever
#   org.localsend.localsend_app
#   org.openrgb.OpenRGB
#   io.github.philipk.boilr
#   org.freedesktop.Piper
#   com.github.mtkennerly.ludusavi
#   com.stremio.Stremio
#   info.febvre.Komikku
#   com.cassidyjames.butler
#   io.github.prateekmedia.appimagepool
#   io.github.giantpinkrobots.flatsweep
#   com.vysp3r.RetroPlus
#   com.vysp3r.ProtonPlus
# )
case "$1" in
arch) sudo pacman -S --needed "${arch[@]}" ;;
aur) paru -S --needed --skipreview "${aur[@]}" ;;
hypr) paru -S --needed --skipreview "${hyper[@]}" ;;
#pak) flatpak install "${flatpak[@]}" ;;
--help | -h) echo "arch aur hypr pak" ;;
esac
