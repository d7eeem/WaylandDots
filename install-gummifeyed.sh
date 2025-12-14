#!/usr/bin/env bash
#|---/ /+--------------------------------+---/ /|#
#|--/ /-| WaylandDots Installation Script |--/ /-|#
#|-/ /--+--------------------------------+-/ /--|#

set -e

# ----------------------------
# Directories
# ----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/Scripts"

# ----------------------------
# UI helpers (GUM)
# ----------------------------
banner() {
  gum style \
    --foreground 212 --border normal --border-foreground 212 --padding "1 4" \
"╦ ╦┌─┐┬ ┬┬  ┌─┐┌┐┌┌┬┐╔╦╗┌─┐┌┬┐┌─┐
║║║├─┤└┬┘│  ├─┤│││ ││ ║║│ │ │ └─┐
╚╩╝┴ ┴ ┴ ┴─┘┴ ┴┘└┘─┴┘═╩╝└─┘ ┴ └─┘
Installation Script"
}

step() {
  gum style --bold --foreground 75 "==> $1"
}

info() {
  gum log --level info "$1"
}

warn() {
  gum log --level warn "$1"
}

error() {
  gum log --level error "$1"
  exit 1
}

success() {
  gum log --level info "✔ $1"
}

# ----------------------------
# Checks
# ----------------------------
check_dependencies() {
  step "Checking dependencies"
  local missing=()
  for cmd in git stow gum; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if [ ${#missing[@]} -ne 0 ]; then
    error "Missing dependencies: ${missing[*]}"
  fi
  success "All dependencies installed"
}

# ----------------------------
# Dotfile packages
# ----------------------------
list_packages() {
  for dir in "${SCRIPT_DIR}"/*/; do
    name="$(basename "$dir")"
    [[ "$name" == "Scripts" || "$name" == ".git" || "$name" == "Source" || "$name" == ".claude" ]] && continue
    if [ -d "$dir/.config" ] || [ -d "$dir/.local" ]; then
      echo "$name"
    fi
  done
}

choose_packages() {
  list_packages | gum choose --no-limit --header "Select dotfile packages"
}

# ----------------------------
# Actions
# ----------------------------
install_packages() {
  step "Installing system packages"
  if [ ! -f "${SCRIPTS_DIR}/install.sh" ]; then
    warn "Scripts/install.sh not found — skipping"
    return
  fi
  (cd "$SCRIPTS_DIR" && bash ./install.sh) || {
    gum confirm "Package install failed. Continue anyway?" || exit 1
  }
  success "Package installation finished"
}

deploy_dotfiles() {
  step "Deploying dotfiles"
  if [ ! -x "${SCRIPT_DIR}/stow.sh" ]; then
    error "stow.sh not found or not executable"
  fi
  bash "${SCRIPT_DIR}/stow.sh" "$@"
}

# ----------------------------
# Main
# ----------------------------
main() {
  banner
  echo
  check_dependencies
  echo
  
  ACTION=$(gum choose \
    "Install packages + stow dotfiles" \
    "Install packages only" \
    "Stow dotfiles only" \
    "Stow specific packages" \
    "Unstow packages" \
    "List packages")
  
  case "$ACTION" in
    "Install packages + stow dotfiles")
      install_packages
      deploy_dotfiles
      ;;
    "Install packages only")
      install_packages
      ;;
    "Stow dotfiles only")
      deploy_dotfiles
      ;;
    "Stow specific packages")
      pkgs=$(choose_packages)
      deploy_dotfiles $pkgs
      ;;
    "Unstow packages")
      pkgs=$(choose_packages)
      deploy_dotfiles -D $pkgs
      ;;
    "List packages")
      step "Available packages"
      list_packages | gum style --foreground 212
      ;;
  esac
  
  echo
  success "Installation complete"
  gum style --foreground 240 "
Next steps:
  • Review ~/.config
  • Restart your session
  • Check Scripts/install.sh output
"
}

main "$@"
