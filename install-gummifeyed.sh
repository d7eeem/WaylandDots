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
PKG_LIST="${SCRIPTS_DIR}/cu_pkg_core.lst"
FPK_LIST="${SCRIPTS_DIR}/custom_flat.lst"
UFW_LIST="${SCRIPTS_DIR}/custom_ufw.lst"

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
# Package Management Functions
# ----------------------------
add_package() {
  local pkg="$1"
  local list_file="$2"
  local list_type="$3"
  
  if [ -z "$pkg" ]; then
    error "Package name cannot be empty"
  fi
  
  if [ ! -f "$list_file" ]; then
    warn "$list_file not found, creating it..."
    mkdir -p "$(dirname "$list_file")"
    touch "$list_file"
  fi
  
  # Check if package already exists in list
  if grep -q "^${pkg}[[:space:]]*\(#\|$\)" "$list_file" 2>/dev/null; then
    warn "$pkg already exists in $list_type list"
    
    # Check if already installed
    if [ "$list_type" = "package" ]; then
      if [ -f "${SCRIPTS_DIR}/global_fn.sh" ]; then
        source "${SCRIPTS_DIR}/global_fn.sh"
        if pkg_installed "${pkg}" 2>/dev/null; then
          info "$pkg is already installed on your system"
          exit 0
        fi
      fi
    elif [ "$list_type" = "flatpak" ]; then
      if command -v flatpak &>/dev/null && flatpak list --app 2>/dev/null | grep -q "${pkg}"; then
        info "$pkg is already installed on your system"
        exit 0
      fi
    elif [ "$list_type" = "ufw" ]; then
      if command -v ufw &>/dev/null && sudo ufw status 2>/dev/null | grep -q "${pkg%%/*}"; then
        info "UFW rule for $pkg already exists"
        exit 0
      fi
    fi
    
    # Ask if they want to install it anyway
    if command -v gum >/dev/null 2>&1; then
      if gum confirm "$pkg is in the list but may not be applied. Apply it now?"; then
        return 0
      else
        exit 0
      fi
    else
      read -p "$pkg is in the list but may not be applied. Apply it now? (y/N): " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
      else
        exit 0
      fi
    fi
  fi
  
  # Verify package exists before adding (for packages only, not flatpaks or ufw)
  if [ "$list_type" = "package" ]; then
    info "Verifying package name: $pkg"
    
    # Source global functions for package checking
    if [ -f "${SCRIPTS_DIR}/global_fn.sh" ]; then
      source "${SCRIPTS_DIR}/global_fn.sh"
      
      # Ensure AUR helper is available for checking
      if ! chk_list "aurhlpr" "${aurList[@]}" 2>/dev/null; then
        warn "No AUR helper found, installing yay for package verification..."
        bash "${SCRIPTS_DIR}/install_aur.sh" "yay" &>/dev/null || true
        chk_list "aurhlpr" "${aurList[@]}" 2>/dev/null || true
      fi
      
      # Check if package exists in repos or AUR
      local pkg_found=false
      
      if pkg_available "${pkg}" 2>/dev/null; then
        pkg_found=true
        local repo=$(pacman -Si "${pkg}" 2>/dev/null | awk -F ': ' '/Repository / {print $2}')
        success "Package found in official repository: $repo"
      elif aur_available "${pkg}" 2>/dev/null; then
        pkg_found=true
        success "Package found in AUR"
      fi
      
      if [ "$pkg_found" = false ]; then
        error "Package '$pkg' not found in official repos or AUR. Please check the package name."
        
        # Suggest similar packages
        info "Searching for similar package names..."
        if command -v "${aurhlpr}" &>/dev/null; then
          echo ""
          "${aurhlpr}" -Ss "^${pkg}" 2>/dev/null | head -n 10 || true
          echo ""
          warn "Did you mean one of the packages above?"
        fi
        return 1
      fi
    else
      warn "Cannot verify package (global_fn.sh not found), adding anyway..."
    fi
  elif [ "$list_type" = "flatpak" ]; then
    info "Verifying flatpak name: $pkg"
    
    # Ensure flatpak is installed
    if ! command -v flatpak &>/dev/null; then
      warn "Flatpak not installed, cannot verify. Installing flatpak first..."
      sudo pacman -S --noconfirm flatpak 2>/dev/null || true
    fi
    
    # Add Flathub if needed
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    
    # Try to search for the flatpak
    if command -v flatpak &>/dev/null; then
      if flatpak search "${pkg}" 2>/dev/null | grep -q "${pkg}"; then
        success "Flatpak found in Flathub"
      else
        warn "Cannot verify flatpak '$pkg' in Flathub"
        
        # Show search results
        info "Searching Flathub for similar names..."
        echo ""
        flatpak search "${pkg}" 2>/dev/null | head -n 10 || true
        echo ""
        
        if command -v gum >/dev/null 2>&1; then
          if ! gum confirm "Flatpak may not exist. Add to list anyway?"; then
            info "Cancelled. Package not added."
            exit 0
          fi
        else
          read -p "Flatpak may not exist. Add to list anyway? (y/N): " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Cancelled. Package not added."
            exit 0
          fi
        fi
      fi
    fi
  elif [ "$list_type" = "ufw" ]; then
    info "Validating UFW rule format: $pkg"
    
    # Basic validation of port/protocol format
    if ! [[ "$pkg" =~ ^[0-9]+(:[0-9]+)?(/[a-z]+)?$ ]]; then
      warn "Rule format may be invalid. Expected format: PORT[/PROTOCOL] or START:END[/PROTOCOL]"
      warn "Examples: 22, 22/tcp, 8000:8100/udp"
      
      if command -v gum >/dev/null 2>&1; then
        if ! gum confirm "Continue anyway?"; then
          info "Cancelled. Rule not added."
          exit 0
        fi
      else
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          info "Cancelled. Rule not added."
          exit 0
        fi
      fi
    else
      success "UFW rule format valid"
    fi
  fi
  
  # Add package to list
  echo "$pkg" >> "$list_file"
  success "Added $pkg to $list_type list ($list_file)"
  
  # Ask if user wants to install/apply now
  local action_text="Install"
  [ "$list_type" = "ufw" ] && action_text="Apply"
  
  if command -v gum >/dev/null 2>&1; then
    if gum confirm "$action_text $pkg now?"; then
      return 0
    else
      info "Skipping. Run the installer later to $action_text."
      exit 0
    fi
  else
    read -p "$action_text $pkg now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      return 0
    else
      info "Skipping. Run the installer later to $action_text."
      exit 0
    fi
  fi
}

install_single_pkg() {
  local pkg="$1"
  
  step "Installing package: $pkg"
  
  # Source global functions if available
  if [ -f "${SCRIPTS_DIR}/global_fn.sh" ]; then
    source "${SCRIPTS_DIR}/global_fn.sh"
    
    # Ensure AUR helper is installed (silently)
    if ! chk_list "aurhlpr" "${aurList[@]}" 2>/dev/null; then
      info "No AUR helper detected, installing one..."
      bash "${SCRIPTS_DIR}/install_aur.sh" "yay" 2>&1 > /dev/null || {
        warn "Failed to install AUR helper"
      }
      chk_list "aurhlpr" "${aurList[@]}" 2>/dev/null
    fi
  fi
  
  # Check if package installation script exists and use it
  if [ -f "${SCRIPTS_DIR}/install_pkg.sh" ]; then
    # Create temporary list with single package
    local tmp_list=$(mktemp)
    echo "$pkg" > "$tmp_list"
    
    info "Using install_pkg.sh to install $pkg..."
    bash "${SCRIPTS_DIR}/install_pkg.sh" "$tmp_list"
    local result=$?
    rm "$tmp_list"
    
    if [ $result -eq 0 ]; then
      success "Package $pkg installed"
    else
      error "Failed to install package $pkg"
    fi
  else
    # Fallback to direct installation
    info "install_pkg.sh not found, trying direct installation..."
    
    # Check if already installed
    if command -v pacman &>/dev/null && pacman -Q "${pkg}" &>/dev/null; then
      success "$pkg is already installed"
      return 0
    fi
    
    # Try official repos first
    if command -v pacman &>/dev/null && pacman -Si "${pkg}" &>/dev/null; then
      info "Installing $pkg from official repositories..."
      sudo pacman -S --noconfirm "$pkg"
    # Then try AUR helpers
    elif command -v yay &>/dev/null; then
      info "Installing $pkg via yay..."
      yay -S --noconfirm "$pkg"
    elif command -v paru &>/dev/null; then
      info "Installing $pkg via paru..."
      paru -S --noconfirm "$pkg"
    else
      error "No package manager available to install $pkg"
    fi
    
    # Verify installation
    if command -v pacman &>/dev/null && pacman -Q "${pkg}" &>/dev/null; then
      success "Package $pkg installed successfully"
    else
      warn "Package $pkg may not have installed correctly"
    fi
  fi
}

install_single_flatpak() {
  local pkg="$1"
  
  step "Installing flatpak: $pkg"
  
  # Check if flatpak is installed
  if ! command -v flatpak >/dev/null 2>&1; then
    info "Flatpak not found, installing..."
    
    # Use install.sh to install flatpak if it exists
    if [ -f "${SCRIPTS_DIR}/install_fpk.sh" ]; then
      bash "${SCRIPTS_DIR}/install_fpk.sh" || {
        warn "install_fpk.sh failed, trying direct installation..."
        sudo pacman -S --noconfirm flatpak
      }
    else
      sudo pacman -S --noconfirm flatpak
    fi
    
    success "Flatpak installed"
  fi
  
  # Add Flathub if not exists
  info "Ensuring Flathub repository is configured..."
  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  
  # Install the flatpak
  info "Installing $pkg from Flathub..."
  flatpak install --user -y flathub "$pkg" || {
    error "Failed to install flatpak: $pkg"
  }
  
  # Apply GTK theme overrides
  info "Applying theme overrides..."
  local gtkTheme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | sed "s/'//g" || echo "Adwaita")
  local gtkIcon=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | sed "s/'//g" || echo "Adwaita")
  
  flatpak --user override \
    --filesystem=~/.themes \
    --filesystem=~/.icons \
    --env=GTK_THEME="${gtkTheme}" \
    --env=ICON_THEME="${gtkIcon}"
  
  success "Flatpak $pkg installed and configured"
}

apply_single_ufw_rule() {
  local rule="$1"
  
  step "Applying UFW rule: $rule"
  
  # Check if UFW is installed
  if ! command -v ufw >/dev/null 2>&1; then
    info "UFW not found, installing..."
    sudo pacman -S --noconfirm ufw || error "Failed to install UFW"
    success "UFW installed"
  fi
  
  # Enable UFW if not enabled
  if ! sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    info "Enabling UFW..."
    if command -v gum >/dev/null 2>&1; then
      if gum confirm "UFW is not enabled. Enable it now?"; then
        sudo ufw --force enable || error "Failed to enable UFW"
        success "UFW enabled"
      else
        warn "UFW not enabled, rule will be added but not active"
      fi
    else
      read -p "UFW is not enabled. Enable it now? (y/N): " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ufw --force enable || error "Failed to enable UFW"
        success "UFW enabled"
      else
        warn "UFW not enabled, rule will be added but not active"
      fi
    fi
  fi
  
  # Apply the rule
  info "Adding UFW rule: $rule"
  sudo ufw allow "$rule" 2>/dev/null || {
    warn "Failed to add rule or rule already exists: $rule"
  }
  
  success "UFW rule applied: $rule"
}

configure_ufw() {
  step "Configuring UFW firewall"
  
  if [ ! -f "$UFW_LIST" ]; then
    warn "UFW rules list not found: $UFW_LIST"
    return
  fi
  
  # Check if UFW is installed
  if ! command -v ufw >/dev/null 2>&1; then
    info "UFW not found, installing..."
    sudo pacman -S --noconfirm ufw || {
      error "Failed to install UFW"
      return
    }
    success "UFW installed"
  fi
  
  # Ask to enable UFW if not already enabled
  if ! sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    info "UFW is not currently enabled"
    if command -v gum >/dev/null 2>&1; then
      if gum confirm "Enable UFW firewall now?"; then
        sudo ufw --force enable || error "Failed to enable UFW"
        success "UFW enabled"
      else
        warn "Skipping UFW configuration (firewall not enabled)"
        return
      fi
    else
      read -p "Enable UFW firewall now? (y/N): " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ufw --force enable || error "Failed to enable UFW"
        success "UFW enabled"
      else
        warn "Skipping UFW configuration (firewall not enabled)"
        return
      fi
    fi
  fi
  
  # Apply rules from list
  # Read all rules into an array first to avoid stdin issues
  local rules=()
  while IFS= read -r rule || [ -n "$rule" ]; do
    # Skip empty lines and comments
    [[ -z "$rule" || "$rule" =~ ^[[:space:]]*# ]] && continue
    
    # Extract port/protocol (remove inline comments)
    rule=$(echo "$rule" | sed 's/#.*//' | xargs)
    [ -z "$rule" ] && continue
    
    rules+=("$rule")
  done < "$UFW_LIST"
  
  # Now process the rules
  local count=0
  local skipped=0
  
  for rule in "${rules[@]}"; do
    info "Allowing: $rule"
    
    # Capture UFW output to detect if rule already exists
    local ufw_output
    ufw_output=$(sudo ufw allow "$rule" 2>&1)
    local ufw_exit=$?
    
    if [ $ufw_exit -eq 0 ]; then
      # Check if the output indicates the rule already existed
      if echo "$ufw_output" | grep -q "Skipping adding existing rule"; then
        info "Rule already exists: $rule"
        skipped=$((skipped + 1))
      else
        success "Rule added: $rule"
        count=$((count + 1))
      fi
    else
      warn "Failed to add rule: $rule"
    fi
  done
  
  if [ $count -gt 0 ] || [ $skipped -gt 0 ]; then
    if [ $count -gt 0 ]; then
      success "Applied $count new UFW rule(s)"
    fi
    if [ $skipped -gt 0 ]; then
      info "$skipped rule(s) already existed"
    fi
    echo ""
    info "Current UFW status:"
    sudo ufw status numbered
  else
    warn "No rules found in $UFW_LIST"
  fi
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
# Argument Parsing
# ----------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --add-pkg)
        if [ -z "$2" ]; then
          error "--add-pkg requires a package name"
        fi
        add_package "$2" "$PKG_LIST" "package"
        if [ $? -eq 0 ]; then
          install_single_pkg "$2"
        fi
        exit 0
        ;;
      --add-fpk)
        if [ -z "$2" ]; then
          error "--add-fpk requires a flatpak name"
        fi
        add_package "$2" "$FPK_LIST" "flatpak"
        if [ $? -eq 0 ]; then
          install_single_flatpak "$2"
        fi
        exit 0
        ;;
      --add-ufw)
        if [ -z "$2" ]; then
          error "--add-ufw requires a port/protocol (e.g., 22/tcp, 8000:9000/udp)"
        fi
        add_package "$2" "$UFW_LIST" "ufw"
        if [ $? -eq 0 ]; then
          apply_single_ufw_rule "$2"
        fi
        exit 0
        ;;
      --configure-ufw)
        configure_ufw
        exit 0
        ;;
      -h|--help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --add-pkg NAME       Add package to cu_pkg_core.lst and optionally install"
        echo "  --add-fpk NAME       Add flatpak to custom_flat.lst and optionally install"
        echo "  --add-ufw RULE       Add UFW rule to custom_ufw.lst and optionally apply"
        echo "                       Format: PORT[/PROTOCOL] or START:END[/PROTOCOL]"
        echo "                       Examples: 22, 22/tcp, 8000:8100/udp"
        echo "  --configure-ufw      Configure UFW using custom_ufw.lst"
        echo "  -h, --help           Show this help message"
        echo ""
        echo "Interactive mode will run if no options are provided."
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        ;;
    esac
  done
}

# ----------------------------
# Main
# ----------------------------
main() {
  # Check for arguments first
  if [ $# -gt 0 ]; then
    parse_args "$@"
  fi
  
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
    "Configure UFW firewall" \
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
    "Configure UFW firewall")
      configure_ufw
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
  • Review firewall rules: sudo ufw status
"
}

main "$@"
