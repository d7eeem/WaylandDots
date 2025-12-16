#!/usr/bin/env bash
set -e

# Configuration
USER_ID=$(id -u)
GROUP_ID=$(id -g)
MOUNT_OPTIONS="uid=${USER_ID},gid=${GROUP_ID},rw,user,exec,umask=000"
DRY_RUN=false

# Check for gum
if ! command -v gum &> /dev/null; then
    echo "Error: gum is not installed"
    echo "Install with: https://github.com/charmbracelet/gum#installation"
    exit 1
fi

# Check if running as root
check_permissions() {
    if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then 
        gum style --foreground 196 --bold "ERROR: Please run as root or with sudo (or use --dry-run to preview)"
        exit 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        gum style --foreground 214 --bold "⚠ DRY-RUN MODE - No changes will be made"
        echo ""
    fi
}

# Backup fstab
backup_fstab() {
    local backup="/etc/fstab.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ "$DRY_RUN" = true ]; then
        gum style --foreground 213 "Would create backup: $backup"
    else
        gum spin --spinner dot --title "Creating backup..." -- sleep 0.5
        cp /etc/fstab "$backup"
        gum style --foreground 82 "✓ Backup created: $backup"
    fi
}

# Find NTFS partitions
find_ntfs_partitions() {
    gum spin --spinner dot --title "Searching for NTFS partitions..." -- sleep 0.5
    
    # Get NTFS partitions with UUID and LABEL
    local ntfs_parts
    ntfs_parts=$(lsblk -no NAME,FSTYPE,UUID,LABEL,SIZE | awk '$2 == "ntfs" {print $0}')
    
    if [ -z "$ntfs_parts" ]; then
        gum style --foreground 214 "⚠ No NTFS partitions found"
        return 1
    fi
    
    echo "$ntfs_parts"
}

# Interactive selection of partitions
select_partitions() {
    local ntfs_list="$1"
    
    gum style --border double --padding "1 2" --border-foreground 212 "Found NTFS Partitions"
    echo ""
    
    # Create a temporary file to store selections
    local temp_file=$(mktemp)
    
    # Parse each NTFS partition
    while IFS= read -r line; do
        local name=$(echo "$line" | awk '{print $1}')
        local uuid=$(echo "$line" | awk '{print $3}')
        local label=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | xargs)
        local size=$(echo "$line" | awk '{print $NF}')
        
        [ -z "$uuid" ] && continue
        
        # Display partition info
        echo "$(gum style --foreground 212 --bold "Partition:") $(gum style --foreground 117 "/dev/$name")"
        echo "  $(gum style --foreground 228 "UUID:")  $uuid"
        echo "  $(gum style --foreground 156 "Label:") ${label:-<no label>}"
        echo "  $(gum style --foreground 183 "Size:")  $size"
        echo ""
        
        # Ask if user wants to mount this partition
        if gum confirm "Mount this partition?"; then
            # Get mount point
            local mount_point
            mount_point=$(gum input --placeholder "/mnt/windows" --prompt "Mount point: " --prompt.foreground 212)
            
            if [ -n "$mount_point" ]; then
                # Validate mount point
                if [[ ! "$mount_point" =~ ^/mnt/ ]]; then
                    gum style --foreground 214 "⚠ Mount point should start with /mnt/, skipping..."
                    echo ""
                    continue
                fi
                
                # Save to temp file
                echo "$uuid|$mount_point|${label:-no-label}" >> "$temp_file"
                gum style --foreground 82 "✓ Will mount $uuid to $mount_point"
            fi
        fi
        echo ""
    done <<< "$ntfs_list"
    
    # Read from temp file and output
    if [ -s "$temp_file" ]; then
        cat "$temp_file"
    fi
    
    rm -f "$temp_file"
}

# Add entries to fstab
add_to_fstab() {
    local entries=("$@")
    
    if [ ${#entries[@]} -eq 0 ]; then
        gum style --foreground 214 "⚠ No partitions selected for mounting"
        return
    fi
    
    if [ "$DRY_RUN" = true ]; then
        gum style --foreground 213 --bold "Would add the following entries to /etc/fstab:"
        echo ""
        echo "# NTFS partitions added on $(date)"
    else
        echo "" >> /etc/fstab
        echo "# NTFS partitions added on $(date)" >> /etc/fstab
    fi
    
    for entry in "${entries[@]}"; do
        IFS='|' read -r uuid mount_point label <<< "$entry"
        
        # Create mount point if it doesn't exist
        if [ ! -d "$mount_point" ]; then
            if [ "$DRY_RUN" = true ]; then
                gum style --foreground 213 "Would create mount point: $mount_point"
            else
                mkdir -p "$mount_point"
                gum style --foreground 117 "Created mount point: $mount_point"
            fi
        fi
        
        # Check if UUID already in fstab
        if grep -q "UUID=$uuid" /etc/fstab 2>/dev/null; then
            gum style --foreground 214 "⚠ UUID=$uuid already in fstab, skipping..."
            continue
        fi
        
        # Add fstab entry
        local fstab_line="UUID=$uuid   $mount_point   ntfs   $MOUNT_OPTIONS   0 0"
        
        if [ "$DRY_RUN" = true ]; then
            echo "$fstab_line"
        else
            echo "$fstab_line" >> /etc/fstab
            gum style --foreground 82 "✓ Added: $mount_point ($label)"
        fi
    done
    
    if [ "$DRY_RUN" = false ]; then
        echo "" >> /etc/fstab
    fi
    echo ""
}

# Mount all new entries
mount_partitions() {
    if [ "$DRY_RUN" = true ]; then
        gum style --foreground 213 "Would run: mount -a"
        return
    fi
    
    gum spin --spinner dot --title "Mounting partitions..." -- mount -a 2>&1 || true
    gum style --foreground 82 "✓ All partitions mounted"
}

# Main
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                gum style --border double --padding "1 2" --border-foreground 212 \
                    "NTFS Partition Auto-Mount Setup" \
                    "" \
                    "Finds NTFS partitions and adds them to /etc/fstab" \
                    "for automatic mounting at boot."
                echo ""
                gum style --bold "Usage:"
                echo "  $0 [OPTIONS]"
                echo ""
                gum style --bold "Options:"
                echo "  --dry-run, -n    Show what would be done without making changes"
                echo "  --help, -h       Show this help message"
                echo ""
                exit 0
                ;;
            *)
                gum style --foreground 196 "ERROR: Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
    
    gum style \
        --border double \
        --padding "1 2" \
        --border-foreground 212 \
        --align center \
        "NTFS Partition Auto-Mount Setup"
    
    echo ""
    check_permissions
    
    # Find NTFS partitions
    local ntfs_list
    ntfs_list=$(find_ntfs_partitions) || exit 0
    
    echo ""
    
    # Let user select and configure
    local -a selected_parts
    mapfile -t selected_parts < <(select_partitions "$ntfs_list")
    
    if [ ${#selected_parts[@]} -eq 0 ]; then
        gum style --foreground 117 "ℹ No partitions selected. Exiting."
        exit 0
    fi
    
    # Show summary
    echo ""
    gum style --border double --padding "1 2" --border-foreground 82 "Summary of Changes"
    echo ""
    
    for entry in "${selected_parts[@]}"; do
        IFS='|' read -r uuid mount_point label <<< "$entry"
        echo "  $(gum style --foreground 117 "UUID=$uuid") $(gum style --foreground 228 "→") $(gum style --foreground 156 "$mount_point") $(gum style --foreground 242 "($label)")"
    done
    echo ""
    
    # Confirm before making changes
    if [ "$DRY_RUN" = false ]; then
        if ! gum confirm "Proceed with these changes?"; then
            gum style --foreground 117 "ℹ Cancelled by user"
            exit 0
        fi
        echo ""
    fi
    
    # Make changes
    backup_fstab
    add_to_fstab "${selected_parts[@]}"
    mount_partitions
    
    echo ""
    if [ "$DRY_RUN" = true ]; then
        gum style --border rounded --padding "1 2" --border-foreground 82 \
            "✓ Dry-run complete! No changes were made." \
            "" \
            "Run without --dry-run to apply these changes"
    else
        gum style --border rounded --padding "1 2" --border-foreground 82 "✓ Setup complete!"
        echo ""
        gum style --foreground 117 --bold "Current NTFS mounts:"
        df -h -t ntfs 2>/dev/null | tail -n +2 || echo "  (none mounted yet)"
    fi
}

main "$@"
