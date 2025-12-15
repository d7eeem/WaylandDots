#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Requirements
# ----------------------------
command -v stow >/dev/null || { echo "stow is required"; exit 1; }
command -v gum  >/dev/null || { echo "gum is required: https://github.com/charmbracelet/gum"; exit 1; }

# ----------------------------
# Paths & Config
# ----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME"
EXCLUDED_DIRS=("Scripts" "Source" ".git" ".claude")

# ----------------------------
# UI Helpers (Gum)
# ----------------------------
banner() {
  gum style \
    --border double \
    --padding "1 4" \
    --align center \
    --foreground 212 \
    "STOW DOTFILES" \
    "Interactive Deployment"
}

info()    { gum log --level info  "$1"; }
warn()    { gum log --level warn  "$1"; }
error()   { gum log --level error "$1"; }
success() { gum style --foreground 82 "✓ $1"; }

# ----------------------------
# Helpers
# ----------------------------
is_excluded() {
  local dir="$1"
  for e in "${EXCLUDED_DIRS[@]}"; do
    [[ "$dir" == "$e" ]] && return 0
  done
  return 1
}

get_all_packages() {
  local pkgs=()
  for d in "$SCRIPT_DIR"/*/; do
    [[ -d "$d" ]] || continue
    local name
    name="$(basename "$d")"
    is_excluded "$name" && continue
    if [[ -d "$d/.config" || -d "$d/.local" ]] || ls -A "$d"/.* &>/dev/null; then
      pkgs+=("$name")
    fi
  done
  printf '%s\n' "${pkgs[@]}"
}

backup_existing() {
  local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$backup_dir"
  info "Creating backup at $backup_dir"
  for pkg in $(get_all_packages); do
    [[ -d "$SCRIPT_DIR/$pkg/.config" ]] || continue
    for c in "$SCRIPT_DIR/$pkg/.config"/*; do
      local name
      name="$(basename "$c")"
      [[ -e "$HOME/.config/$name" ]] || continue
      cp -r "$HOME/.config/$name" "$backup_dir/" 2>/dev/null || true
    done
  done
  success "Backup completed"
}

stow_package() {
  local pkg="$1"
  local op="$2"
  shift 2
  local args=("$@")
  
  gum spin \
    --title="$op $pkg…" \
    -- stow "$op" "${args[@]}" -d "$SCRIPT_DIR" -t "$TARGET_DIR" "$pkg"
}

# ----------------------------
# Interactive Flow
# ----------------------------
interactive() {
  mapfile -t PACKAGES < <(get_all_packages)
  [[ ${#PACKAGES[@]} -eq 0 ]] && {
    error "No packages found"
    exit 1
  }
  
  SELECTED=$(printf "%s\n" "${PACKAGES[@]}" |
    gum choose --no-limit --height 20 --header "Select packages")
  
  [[ -z "$SELECTED" ]] && {
    warn "Nothing selected"
    exit 0
  }
  
  OPERATION=$(gum choose \
    "Stow (-S)" \
    "Unstow (-D)" \
    "Restow (-R)")
  
  case "$OPERATION" in
    *Stow*)   OP="-S" ;;
    *Unstow*) OP="-D" ;;
    *Restow*) OP="-R" ;;
  esac
  
  gum confirm "Create backup before continuing?" && backup_existing
  
  for pkg in $SELECTED; do
    stow_package "$pkg" "$OP"
  done
  
  success "All operations completed"
}

# ----------------------------
# Non-interactive (flags)
# ----------------------------
usage() {
  gum style --border rounded --padding "1 2" "
Usage:
  ./stow.sh            # Interactive mode
  ./stow.sh all        # Stow all
  ./stow.sh list       # List packages
"
}

# ----------------------------
# Main
# ----------------------------
banner

case "${1:-}" in
  "" )
    interactive
    ;;
  list )
    get_all_packages | gum format
    ;;
  all )
    gum confirm "Backup existing configs?" && backup_existing
    for pkg in $(get_all_packages); do
      stow_package "$pkg" "-S"
    done
    success "All packages stowed"
    ;;
  * )
    usage
    ;;
esac
