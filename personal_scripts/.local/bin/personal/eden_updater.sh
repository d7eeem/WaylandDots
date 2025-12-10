#!/bin/bash

# Eden Linux AppImage Updater
# Updates Eden Linux from GitHub releases

set -e

# Configuration
REPO="Eden-CI/PR"
INSTALL_DIR="$HOME/Applications"
OLD_VERSIONS_DIR="$HOME/Applications/old"
APP_NAME="Eden-Linux"
CURRENT_VERSION_FILE="$HOME/.config/eden-linux-version"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get the latest release info
get_latest_release() {
    # Get the latest release tag (send output to stderr for logging)
    print_info "Fetching latest release information..." >&2
    
    # Get all releases and find the one with the highest build number
    # The tag format is: BUILD_NUMBER-COMMIT_HASH (e.g., 3162-07389c4a04)
    local tag=$(curl -s "https://api.github.com/repos/$REPO/releases?per_page=100" | \
        grep -Po '"tag_name": "\K[^"]*' | \
        sort -t'-' -k1 -nr | \
        head -n1)
    
    if [ -z "$tag" ]; then
        print_error "Failed to fetch latest release tag" >&2
        exit 1
    fi
    
    print_info "Latest release: $tag" >&2
    
    # Only return the tag to stdout
    echo "$tag"
}

# Function to extract commit hash from tag
get_commit_from_tag() {
    local tag=$1
    # Tag format: 3162-07389c4a04
    local commit=$(echo "$tag" | cut -d'-' -f2)
    echo "$commit"
}

# Function to extract version number from tag
get_version_from_tag() {
    local tag=$1
    # Tag format: 3162-07389c4a04
    local version=$(echo "$tag" | cut -d'-' -f1)
    echo "$version"
}

# Function to construct download URL
construct_download_url() {
    local tag=$1
    echo "https://github.com/$REPO/releases/download/$tag/$APP_NAME-$tag-amd64-gcc-standard.AppImage"
}

# Function to get current installed version
get_current_version() {
    if [ -f "$CURRENT_VERSION_FILE" ]; then
        cat "$CURRENT_VERSION_FILE"
    else
        echo "none"
    fi
}

# Function to download and install
download_and_install() {
    local tag=$1
    local url=$2
    local temp_file="/tmp/$APP_NAME-$tag.AppImage"
    local final_file="$INSTALL_DIR/$APP_NAME.AppImage"
    
    print_info "Downloading from: $url"
    
    # Download with progress bar
    if ! curl -L --progress-bar -o "$temp_file" "$url"; then
        print_error "Download failed"
        rm -f "$temp_file"
        exit 1
    fi
    
    print_info "Making AppImage executable..."
    chmod +x "$temp_file"
    
    # Create install directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"
    
    # Create old versions directory if it doesn't exist
    mkdir -p "$OLD_VERSIONS_DIR"
    
    # Backup old version if exists
    if [ -f "$final_file" ]; then
        local old_version=$(get_current_version)
        local backup_file="$OLD_VERSIONS_DIR/$APP_NAME-$old_version.AppImage"
        
        print_info "Moving old version to $OLD_VERSIONS_DIR..."
        mv "$final_file" "$backup_file"
        print_success "Old version saved as: $backup_file"
    fi
    
    # Move to final location
    print_info "Installing to $final_file..."
    mv "$temp_file" "$final_file"
    
    # Save version info
    echo "$tag" > "$CURRENT_VERSION_FILE"
    
    print_success "Installation complete!"
    print_info "You can run Eden Linux with: $final_file"
}

# Main update logic
main() {
    echo "========================================="
    echo "  Eden Linux AppImage Updater"
    echo "========================================="
    echo ""
    
    # Get current version
    CURRENT_VERSION=$(get_current_version)
    print_info "Current version: $CURRENT_VERSION"
    
    # Get latest release
    LATEST_TAG=$(get_latest_release)
    
    # Check if update is needed
    if [ "$CURRENT_VERSION" = "$LATEST_TAG" ]; then
        print_success "You already have the latest version!"
        exit 0
    fi
    
    print_info "New version available: $LATEST_TAG"
    
    # Ask for confirmation
    read -p "Do you want to update? (y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Update cancelled"
        exit 0
    fi
    
    # Construct download URL
    DOWNLOAD_URL=$(construct_download_url "$LATEST_TAG")
    
    # Download and install
    download_and_install "$LATEST_TAG" "$DOWNLOAD_URL"
    
    # Show version info
    VERSION_NUM=$(get_version_from_tag "$LATEST_TAG")
    COMMIT_HASH=$(get_commit_from_tag "$LATEST_TAG")
    
    echo ""
    print_success "Updated to version $VERSION_NUM (commit: $COMMIT_HASH)"
    
    # Add to PATH reminder
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo ""
        print_warning "Note: $INSTALL_DIR is not in your PATH"
        print_info "Add this line to your ~/.bashrc or ~/.zshrc:"
        echo "    export PATH=\"\$PATH:$INSTALL_DIR\""
    fi
    
    echo ""
    print_info "Old versions are stored in: $OLD_VERSIONS_DIR"
}

# Run main function
main
