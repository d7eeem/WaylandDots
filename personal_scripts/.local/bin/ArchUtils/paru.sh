#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"

# Ensure base-devel is installed
sudo pacman -S --needed --noconfirm base-devel git

# Clone paru AUR repo
git clone https://aur.archlinux.org/paru.git
cd paru

# Build and install
makepkg -si --noconfirm

