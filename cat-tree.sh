#!/bin/bash

# A script that works like `tree` but prints the content of text files
# in fenced code blocks.
#
# Usage:
#   ./cat-tree.sh [DIRECTORY]
#
# If DIRECTORY is not provided, it defaults to the current directory.

# --- Configuration ---

# Set the target directory. Use the first argument if provided, otherwise default to '.'
TARGET_DIR="${1:-.}"

# List of directory names to ignore.
# Uses find's -name parameter, so wildcards are supported.
IGNORE_DIRS=(".git" "node_modules" "__pycache__" "venv" ".venv" "target")

# --- Validation ---

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found." >&2
    exit 1
fi

# Check for required command: 'file'
if ! command -v file &> /dev/null; then
    echo "Error: The 'file' command is not found. Please install it." >&2
    echo "(On Debian/Ubuntu: sudo apt-get install file)" >&2
    echo "(On Fedora/CentOS: sudo yum install file)" >&2
    echo "(On macOS: brew install file)" >&2
    exit 1
fi

# --- Main Logic ---

# Build the 'find' command's prune arguments for ignoring directories
prune_args=()
for dir in "${IGNORE_DIRS[@]}"; do
    # For the first item, we don't need the '-o' (OR)
    if [ ${#prune_args[@]} -gt 0 ]; then
        prune_args+=("-o")
    fi
    prune_args+=("-name" "$dir")
done

# Use 'find' to locate all files, excluding specified directories.
# - The 'find ... -prune' combination is the standard way to exclude directories.
# - We pipe the output to a 'while' loop.
# - Using -print0 and 'read -d' handles filenames with spaces or newlines.
find "$TARGET_DIR" \( "${prune_args[@]}" \) -prune -o -type f -print0 | while IFS= read -r -d '' file; do
    # Use the 'file' command to determine the MIME type.
    # We check if it's a text file to avoid printing binary garbage.
    mime_type=$(file -b --mime-type "$file")

    if [[ "$mime_type" == text/* || "$mime_type" == application/json || "$mime_type" == application/javascript ]]; then
        # Get the file extension for the code block language identifier.
        # ${file##*.} is a bash parameter expansion to get the string after the last dot.
        extension="${file##*.}"
        
        # If the filename has no extension (e.g., 'Makefile'), the extension will be the
        # full filename. In that case, use a generic or empty identifier.
        if [[ "$extension" == "$file" ]]; then
            lang=""
        else
            lang="$extension"
        fi

        # Print the output in the desired format
        echo "---" # Separator for clarity
        echo "$file"
        echo "\`\`\`$lang"
        cat "$file"
        echo "\`\`\`"
        echo # Add a blank line for better separation between files
    fi
done

