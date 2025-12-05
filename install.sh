#!/usr/bin/env bash
#|---/ /+--------------------------------+---/ /|#
#|--/ /-| WaylandDots Installation Script |--/ /-|#
#|-/ /--+--------------------------------+-/ /--|#

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/Scripts"

# Functions
print_banner() {
    cat <<"EOF"

╦ ╦┌─┐┬ ┬┬  ┌─┐┌┐┌┌┬┐╔╦╗┌─┐┌┬┐┌─┐
║║║├─┤└┬┘│  ├─┤│││ ││ ║║│ │ │ └─┐
╚╩╝┴ ┴ ┴ ┴─┘┴ ┴┘└┘─┴┘═╩╝└─┘ ┴ └─┘
    Installation Script

EOF
}

print_step() {
    echo -e "${CYAN}==>${NC} ${GREEN}$1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_dependencies() {
    print_step "Checking dependencies..."

    local missing_deps=()

    # Check for essential tools
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if ! command -v stow &> /dev/null; then
        missing_deps+=("stow")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install them first:"
        echo "  sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi

    print_success "All dependencies are installed"
}

show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -p, --packages          Install system packages (requires Scripts/install.sh)
    -s, --stow              Deploy dotfiles using stow
    -a, --all               Install packages and deploy dotfiles (default)
    -l, --list              List available dotfile packages
    --stow-only [PACKAGES]  Stow only specific packages (space-separated)
    --unstow [PACKAGES]     Remove specific stowed packages

Examples:
    $0                      # Install packages and deploy all dotfiles
    $0 -p                   # Only install system packages
    $0 -s                   # Only deploy dotfiles
    $0 --stow-only hyprland waybar fish
                            # Deploy only hyprland, waybar, and fish configs
    $0 --unstow hyprland    # Remove hyprland dotfiles

EOF
}

list_packages() {
    print_step "Available dotfile packages:"
    echo ""

    for dir in "${SCRIPT_DIR}"/*/; do
        dirname=$(basename "$dir")
        # Skip non-package directories
        if [[ "$dirname" != "Scripts" && "$dirname" != ".git" && "$dirname" != "Source" ]]; then
            if [ -d "${dir}/.config" ] || [ -d "${dir}/.local" ] || [ -d "${dir}/.$(basename "$dir")" ]; then
                echo "  - $dirname"
            fi
        fi
    done
    echo ""
}

install_packages() {
    print_step "Installing system packages..."

    if [ ! -f "${SCRIPTS_DIR}/install.sh" ]; then
        print_error "Scripts/install.sh not found!"
        print_info "Skipping package installation..."
        return 1
    fi

    cd "${SCRIPTS_DIR}"

    print_info "Running package installation script..."
    echo ""

    if bash ./install.sh "$@"; then
        print_success "Package installation completed"
    else
        print_warn "Package installation encountered issues"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    cd "${SCRIPT_DIR}"
}

deploy_dotfiles() {
    print_step "Deploying dotfiles with stow..."

    if [ ! -x "${SCRIPT_DIR}/stow.sh" ]; then
        print_error "stow.sh not found or not executable!"
        print_info "Please ensure stow.sh exists and is executable"
        exit 1
    fi

    bash "${SCRIPT_DIR}/stow.sh" "$@"
}

# Main script
main() {
    print_banner

    # Default behavior
    DO_PACKAGES=0
    DO_STOW=0
    STOW_ARGS=()

    # Parse arguments
    if [ $# -eq 0 ]; then
        # No arguments: do everything
        DO_PACKAGES=1
        DO_STOW=1
    else
        while [ $# -gt 0 ]; do
            case "$1" in
                -h|--help)
                    show_usage
                    exit 0
                    ;;
                -p|--packages)
                    DO_PACKAGES=1
                    shift
                    ;;
                -s|--stow)
                    DO_STOW=1
                    shift
                    ;;
                -a|--all)
                    DO_PACKAGES=1
                    DO_STOW=1
                    shift
                    ;;
                -l|--list)
                    list_packages
                    exit 0
                    ;;
                --stow-only)
                    DO_STOW=1
                    shift
                    # Collect package names
                    while [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; do
                        STOW_ARGS+=("$1")
                        shift
                    done
                    ;;
                --unstow)
                    DO_STOW=1
                    STOW_ARGS+=("-D")
                    shift
                    # Collect package names
                    while [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; do
                        STOW_ARGS+=("$1")
                        shift
                    done
                    ;;
                *)
                    print_error "Unknown option: $1"
                    echo ""
                    show_usage
                    exit 1
                    ;;
            esac
        done
    fi

    # Run checks
    check_dependencies
    echo ""

    # Execute requested operations
    if [ $DO_PACKAGES -eq 1 ]; then
        install_packages
        echo ""
    fi

    if [ $DO_STOW -eq 1 ]; then
        deploy_dotfiles "${STOW_ARGS[@]}"
        echo ""
    fi

    # Final message
    print_success "Installation complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Review your configurations in ~/.config"
    echo "  2. Restart your session or reboot for all changes to take effect"
    echo "  3. Check Scripts/install.sh output for any warnings"
    echo ""
    print_info "For more information, see README.md"
}

# Run main function
main "$@"
