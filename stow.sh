#!/usr/bin/env bash
#|---/ /+-------------------------+---/ /|#
#|--/ /-| Stow Management Script  |--/ /-|#
#|-/ /--+-------------------------+-/ /--|#

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}"

# Excluded directories (not stow packages)
EXCLUDED_DIRS=("Scripts" "Source" ".git" ".claude")

# Functions
print_banner() {
    cat <<"EOF"

╔═╗┌┬┐┌─┐┬ ┬  ╔╦╗┌─┐┌┐┌┌─┐┌─┐┌─┐┬─┐
╚═╗ │ │ ││││   ║║║├─┤│││├─┤│ ┬├┤ ├┬┘
╚═╝ ┴ └─┘└┴┘  ═╩╝┴ ┴┘└┘┴ ┴└─┘└─┘┴└─
    Dotfiles Deployment

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
    echo -e "${GREEN}[✓]${NC} $1"
}

print_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
}

is_excluded() {
    local dir="$1"
    for excluded in "${EXCLUDED_DIRS[@]}"; do
        if [ "$dir" = "$excluded" ]; then
            return 0
        fi
    done
    return 1
}

get_all_packages() {
    local packages=()
    for dir in "${SCRIPT_DIR}"/*/; do
        if [ -d "$dir" ]; then
            dirname=$(basename "$dir")
            if ! is_excluded "$dirname"; then
                # Check if it contains stowable content
                if [ -d "${dir}/.config" ] || [ -d "${dir}/.local" ] || ls -A "${dir}"/.* &>/dev/null 2>&1; then
                    packages+=("$dirname")
                fi
            fi
        fi
    done
    printf '%s\n' "${packages[@]}"
}

check_stow() {
    if ! command -v stow &> /dev/null; then
        print_error "GNU Stow is not installed!"
        echo ""
        echo "Install it with:"
        echo "  sudo pacman -S stow"
        exit 1
    fi
}

show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [PACKAGES...]

Options:
    -h, --help          Show this help message
    -a, --all           Stow all available packages (default if no packages specified)
    -D, --delete        Unstow (remove) packages instead of stowing
    -R, --restow        Restow packages (unstow then stow again)
    -l, --list          List all available packages
    -n, --dry-run       Show what would be done without doing it
    -v, --verbose       Enable verbose output
    --adopt             Adopt existing files into the stow package

Examples:
    $0                          # Stow all packages
    $0 hyprland waybar          # Stow only hyprland and waybar
    $0 -D hyprland              # Unstow hyprland
    $0 -R waybar                # Restow waybar
    $0 -n -a                    # Dry run for all packages
    $0 --adopt fish             # Adopt existing fish config files

Available Packages:
EOF

    echo ""
    for pkg in $(get_all_packages); do
        echo "  - $pkg"
    done
    echo ""
}

list_packages() {
    print_step "Available dotfile packages:"
    echo ""

    local count=0
    for pkg in $(get_all_packages); do
        echo "  $(( ++count )). $pkg"

        # Show what's inside
        if [ -d "${SCRIPT_DIR}/${pkg}/.config" ]; then
            echo "     └─ Contains .config files"
        fi
        if [ -d "${SCRIPT_DIR}/${pkg}/.local" ]; then
            echo "     └─ Contains .local files"
        fi
    done

    echo ""
    print_info "Total packages: $count"
}

stow_package() {
    local package="$1"
    local operation="$2"  # -S (stow), -D (delete), -R (restow)
    local extra_args=("${@:3}")

    if [ ! -d "${SCRIPT_DIR}/${package}" ]; then
        print_error "Package '$package' not found!"
        return 1
    fi

    local op_name="Stowing"
    case "$operation" in
        -D) op_name="Unstowing" ;;
        -R) op_name="Restowing" ;;
    esac

    echo -ne "${MAGENTA}[$op_name]${NC} $package ... "

    if stow "$operation" "${extra_args[@]}" -d "${SCRIPT_DIR}" -t "${TARGET_DIR}" "$package" 2>&1 | grep -q "WARNING"; then
        echo -e "${YELLOW}WARN${NC}"
        print_warn "Check for conflicts in $package"
    else
        echo -e "${GREEN}OK${NC}"
    fi
}

interactive_mode() {
    print_step "Interactive Package Selection"
    echo ""

    mapfile -t packages < <(get_all_packages)
    local selected=()

    echo "Select packages to stow (space-separated numbers or 'all'):"
    for i in "${!packages[@]}"; do
        echo "  $((i + 1)). ${packages[$i]}"
    done
    echo ""

    read -p "Selection: " -r selection

    if [ "$selection" = "all" ]; then
        selected=("${packages[@]}")
    else
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le "${#packages[@]}" ]; then
                selected+=("${packages[$((num - 1))]}")
            fi
        done
    fi

    if [ ${#selected[@]} -eq 0 ]; then
        print_error "No packages selected!"
        exit 1
    fi

    echo ""
    print_info "Selected packages: ${selected[*]}"
    echo ""

    for pkg in "${selected[@]}"; do
        stow_package "$pkg" -S "${STOW_ARGS[@]}"
    done
}

backup_existing() {
    print_step "Creating backup of existing configs..."

    local backup_dir="${HOME}/.config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    print_info "Backup directory: $backup_dir"

    for pkg in $(get_all_packages); do
        if [ -d "${SCRIPT_DIR}/${pkg}/.config" ]; then
            for config in "${SCRIPT_DIR}/${pkg}/.config"/*; do
                config_name=$(basename "$config")
                if [ -e "${HOME}/.config/${config_name}" ]; then
                    cp -r "${HOME}/.config/${config_name}" "$backup_dir/" 2>/dev/null || true
                    print_info "Backed up: .config/${config_name}"
                fi
            done
        fi
    done

    print_success "Backup completed: $backup_dir"
    echo ""
}

# Main script
main() {
    check_stow

    local OPERATION="-S"  # Default: stow
    local DO_ALL=0
    local DO_LIST=0
    local DO_INTERACTIVE=0
    local DO_BACKUP=0
    local PACKAGES=()
    local STOW_ARGS=()

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                print_banner
                show_usage
                exit 0
                ;;
            -a|--all)
                DO_ALL=1
                shift
                ;;
            -D|--delete|--unstow)
                OPERATION="-D"
                shift
                ;;
            -R|--restow)
                OPERATION="-R"
                shift
                ;;
            -l|--list)
                DO_LIST=1
                shift
                ;;
            -n|--dry-run)
                STOW_ARGS+=("-n")
                shift
                ;;
            -v|--verbose)
                STOW_ARGS+=("-v")
                shift
                ;;
            --adopt)
                STOW_ARGS+=("--adopt")
                shift
                ;;
            -i|--interactive)
                DO_INTERACTIVE=1
                shift
                ;;
            -b|--backup)
                DO_BACKUP=1
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
            *)
                PACKAGES+=("$1")
                shift
                ;;
        esac
    done

    print_banner

    # Handle list mode
    if [ $DO_LIST -eq 1 ]; then
        list_packages
        exit 0
    fi

    # Backup if requested
    if [ $DO_BACKUP -eq 1 ]; then
        backup_existing
    fi

    # Interactive mode
    if [ $DO_INTERACTIVE -eq 1 ]; then
        interactive_mode
        exit 0
    fi

    # Determine packages to process
    if [ ${#PACKAGES[@]} -eq 0 ] || [ $DO_ALL -eq 1 ]; then
        mapfile -t PACKAGES < <(get_all_packages)
        print_info "Processing all packages..."
    else
        print_info "Processing specified packages..."
    fi

    echo ""

    # Process packages
    local success_count=0
    local fail_count=0

    for pkg in "${PACKAGES[@]}"; do
        if stow_package "$pkg" "$OPERATION" "${STOW_ARGS[@]}"; then
            ((success_count++)) || true
        else
            ((fail_count++)) || true
        fi
    done

    echo ""
    print_success "Completed: $success_count successful"

    if [ $fail_count -gt 0 ]; then
        print_warn "Failed: $fail_count packages"
    fi

    echo ""

    # Final tips
    case "$OPERATION" in
        -S)
            print_info "Dotfiles have been stowed to $TARGET_DIR"
            print_info "To remove them, run: $0 -D [packages]"
            ;;
        -D)
            print_info "Dotfiles have been unstowed from $TARGET_DIR"
            ;;
        -R)
            print_info "Dotfiles have been restowed in $TARGET_DIR"
            ;;
    esac
}

# Run main function
main "$@"
