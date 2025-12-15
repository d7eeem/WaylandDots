#!/usr/bin/env bash
#|---/ /+----------------------------------+---/ /|#
#|--/ /-| Main Package Installation Script |--/ /-|#
#|-/ /--+----------------------------------+-/ /--|#

set -e

scrDir=$(dirname "$(realpath "$0")")
baseDir=$(dirname "${scrDir}")

# Source global functions
if [ -f "${scrDir}/global_fn.sh" ]; then
    source "${scrDir}/global_fn.sh"
    log_section="INSTALL"
else
    echo "Warning: global_fn.sh not found, some features may not work"
fi

# ----------------------------
# Configuration
# ----------------------------
PKG_CORE_LIST="${scrDir}/cu_pkg_core.lst"
FLATPAK_LIST="${scrDir}/custom_flat.lst"
AUR_HELPER="${1:-yay}"

# ----------------------------
# Helper Functions
# ----------------------------
print_header() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║    Package Installation - Hyde/Wayland    ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
}

# ----------------------------
# Installation Steps
# ----------------------------

# Step 1: Install AUR Helper
install_aur_helper() {
    if [ -f "${scrDir}/install_aur.sh" ]; then
        print_log -sec "AUR Helper" "Checking for AUR helper..."
        
        if chk_list "aurhlpr" "${aurList[@]}"; then
            print_log -g "✓" " AUR helper detected: ${aurhlpr}"
        else
            print_log -y "Installing AUR helper: ${AUR_HELPER}"
            bash "${scrDir}/install_aur.sh" "${AUR_HELPER}"
            
            if chk_list "aurhlpr" "${aurList[@]}"; then
                print_log -g "✓" " AUR helper installed: ${aurhlpr}"
            else
                print_log -err "Failed to install AUR helper"
                return 1
            fi
        fi
    else
        print_log -warn "install_aur.sh not found, skipping AUR helper installation"
    fi
}

# Step 2: Install Core Packages
install_core_packages() {
    if [ ! -f "${PKG_CORE_LIST}" ]; then
        print_log -warn "Core package list not found: ${PKG_CORE_LIST}"
        return 0
    fi
    
    if [ -f "${scrDir}/install_pkg.sh" ]; then
        print_log -sec "Core Packages" "Installing packages from cu_pkg_core.lst..."
        bash "${scrDir}/install_pkg.sh" "${PKG_CORE_LIST}"
        
        if [ $? -eq 0 ]; then
            print_log -g "✓" " Core packages installed"
        else
            print_log -err "Some core packages failed to install"
            return 1
        fi
    else
        print_log -warn "install_pkg.sh not found, skipping package installation"
    fi
}

# Step 3: Install Flatpaks
install_flatpaks() {
    if [ ! -f "${FLATPAK_LIST}" ]; then
        print_log -warn "Flatpak list not found: ${FLATPAK_LIST}"
        return 0
    fi
    
    if [ -f "${scrDir}/install_fpk.sh" ]; then
        print_log -sec "Flatpak" "Installing flatpak and applications..."
        bash "${scrDir}/install_fpk.sh"
        
        if [ $? -eq 0 ]; then
            print_log -g "✓" " Flatpak applications installed"
        else
            print_log -warn "Some flatpaks may have failed to install"
        fi
    else
        print_log -warn "install_fpk.sh not found, skipping flatpak installation"
    fi
}

# ----------------------------
# Additional Package Lists (Optional)
# ----------------------------
install_additional_lists() {
    # Check for other package lists and install them
    for list_file in "${scrDir}"/*.lst; do
        # Skip core and flatpak lists (already processed)
        [ "$(basename "$list_file")" = "cu_pkg_core.lst" ] && continue
        [ "$(basename "$list_file")" = "custom_flat.lst" ] && continue
        
        if [ -f "$list_file" ]; then
            local list_name=$(basename "$list_file" .lst)
            print_log -sec "Additional" "Found package list: ${list_name}"
            
            # Ask user if they want to install this list
            if command -v gum >/dev/null 2>&1; then
                if gum confirm "Install packages from ${list_name}.lst?"; then
                    bash "${scrDir}/install_pkg.sh" "$list_file"
                fi
            else
                read -p "Install packages from ${list_name}.lst? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    bash "${scrDir}/install_pkg.sh" "$list_file"
                fi
            fi
        fi
    done
}

# ----------------------------
# Post-Installation
# ----------------------------
post_install_cleanup() {
    print_log -sec "Cleanup" "Running post-installation tasks..."
    
    # Clean pacman cache
    if command -v paccache >/dev/null 2>&1; then
        print_log "Cleaning pacman cache..."
        sudo paccache -rk 2
    fi
    
    # Clean AUR helper cache if available
    if chk_list "aurhlpr" "${aurList[@]}"; then
        print_log "Cleaning ${aurhlpr} cache..."
        ${aurhlpr} -Sc --noconfirm 2>/dev/null || true
    fi
    
    # Update font cache
    if command -v fc-cache >/dev/null 2>&1; then
        print_log "Updating font cache..."
        fc-cache -fv >/dev/null 2>&1 || true
    fi
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        print_log "Updating desktop database..."
        update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    fi
    
    print_log -g "✓" " Post-installation cleanup complete"
}

# ----------------------------
# Summary
# ----------------------------
print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║          Installation Complete!            ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    print_log -g "Summary:"
    
    # Count installed packages
    local total_pkgs=$(pacman -Qq | wc -l)
    print_log "  • Total system packages: ${total_pkgs}"
    
    if command -v flatpak >/dev/null 2>&1; then
        local total_flatpaks=$(flatpak list --app 2>/dev/null | wc -l)
        print_log "  • Total flatpak apps: ${total_flatpaks}"
    fi
    
    if chk_list "aurhlpr" "${aurList[@]}"; then
        print_log "  • AUR helper: ${aurhlpr}"
    fi
    
    echo ""
    print_log -y "Next steps:"
    print_log "  1. Deploy dotfiles with stow"
    print_log "  2. Restart your session"
    print_log "  3. Configure your environment"
    echo ""
}

# ----------------------------
# Main Execution
# ----------------------------
main() {
    print_header
    
    # Step 1: AUR Helper
    install_aur_helper || {
        print_log -err "Failed to install AUR helper. Continue anyway? (y/N)"
        read -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    }
    
    # Step 2: Core Packages
    install_core_packages || {
        print_log -warn "Some core packages failed. Continuing..."
    }
    
    # Step 3: Flatpaks
    install_flatpaks || {
        print_log -warn "Some flatpaks failed. Continuing..."
    }
    
    # Step 4: Additional Lists (optional)
    install_additional_lists
    
    # Step 5: Cleanup
    post_install_cleanup
    
    # Step 6: Summary
    print_summary
    
    print_log -g "✓" " All done!"
}

# Run with error handling
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
