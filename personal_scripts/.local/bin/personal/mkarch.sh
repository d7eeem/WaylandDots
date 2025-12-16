#!/bin/sh

# Check if gum is installed
if ! command -v gum >/dev/null 2>&1; then
    echo "Error: gum is not installed. Install it from: https://github.com/charmbracelet/gum"
    exit 1
fi

# Function to show help
show_help() {
    gum style \
        --border double \
        --padding "1 2" \
        --border-foreground 212 \
        "📦 Archiver - Create compressed archives with style" \
        "" \
        "Usage: archiver [format] [archive_name] [source]" \
        "" \
        "Formats:" \
        "  tar  - TAR archive" \
        "  zip  - ZIP archive" \
        "  7z   - 7-Zip archive" \
        "  rar  - RAR archive" \
        "  tgz  - TAR.GZ compressed archive" \
        "" \
        "Example: archiver zip myarchive /path/to/folder"
}

# If no arguments or help requested, show help
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Get arguments
FORMAT="$1"
ARCHIVE_NAME="$2"
SOURCE="${3:-.}"  # Default to current directory if not specified

# Validate format
case "$FORMAT" in
    tar|zip|7z|rar|tgz) ;;
    *)
        gum style --foreground 196 "❌ Invalid format: $FORMAT"
        echo ""
        show_help
        exit 1
        ;;
esac

# Check if archive name is provided
if [ -z "$ARCHIVE_NAME" ]; then
    gum style --foreground 196 "❌ Archive name is required"
    echo ""
    show_help
    exit 1
fi

# Check if source exists
if [ ! -e "$SOURCE" ]; then
    gum style --foreground 196 "❌ Source not found: $SOURCE"
    exit 1
fi

# Confirm action
echo ""
gum style --foreground 212 "📦 Archive Details:"
echo ""
gum style --foreground 147 "Format:  $FORMAT"
gum style --foreground 147 "Name:    $ARCHIVE_NAME"
gum style --foreground 147 "Source:  $SOURCE"
echo ""

if ! gum confirm "Create archive?"; then
    echo ""
    gum style --foreground 214 "⚠️  Cancelled"
    exit 0
fi

# Show progress header
echo ""
gum style --foreground 147 "📝 Creating archive with verbose output..."
echo ""

# Create archive with verbose output
case "$FORMAT" in
    tar) tar -cvf "$ARCHIVE_NAME.tar" "$SOURCE" ;;
    zip) zip -r "$ARCHIVE_NAME.zip" "$SOURCE" ;;
    7z) 7z a "$ARCHIVE_NAME.7z" "$SOURCE" ;;
    rar) 7z a "$ARCHIVE_NAME.rar" "$SOURCE" ;;
    tgz) tar -czf "$ARCHIVE_NAME.tar.gz" "$SOURCE" ;;
esac

# Check if successful
if [ $? -eq 0 ]; then
    # Get file size
    case "$FORMAT" in
        tar) OUTPUT="$ARCHIVE_NAME.tar" ;;
        zip) OUTPUT="$ARCHIVE_NAME.zip" ;;
        7z) OUTPUT="$ARCHIVE_NAME.7z" ;;
        rar) OUTPUT="$ARCHIVE_NAME.rar" ;;
        tgz) OUTPUT="$ARCHIVE_NAME.tar.gz" ;;
    esac
    
    SIZE=$(du -h "$OUTPUT" 2>/dev/null | cut -f1)
    
    echo ""
    gum style \
        --border rounded \
        --padding "1 2" \
        --border-foreground 76 \
        --foreground 76 \
        "✅ Archive created successfully!" \
        "" \
        "📄 File: $OUTPUT" \
        "💾 Size: $SIZE"
else
    echo ""
    gum style --foreground 196 "❌ Failed to create archive"
    exit 1
fi
