#!/bin/bash
#
# diff-tracker: A tool to track changes in a command's output.
#
# It allows you to save a command and then repeatedly run it to see
# what has changed since the last execution.

set -euo pipefail

# --- HELPERS ---

# Prints usage information and exits.
usage() {
    cat <<EOF
Usage: $(basename "$0") <subcommand>

Subcommands:
  new <command>      Creates a new tracker file for the given command.
                     Example: $(basename "$0") new "ls -l /tmp"

  <path_to.json>     Runs the command from the tracker file, shows the diff
                     from the last run, and updates the tracker.
                     Example: $(basename "$0") ls-l-tmp.json
EOF
    exit 1
}

# Checks for required dependencies.
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "Error: 'jq' is not installed. Please install it to use this script." >&2
        exit 1
    fi
}

# --- SUBCOMMANDS ---

# Creates a new JSON file to track a command.
# Arguments:
#   $@: The command to be tracked.
handle_new() {
    local command_to_save="$*"
    if [[ -z "$command_to_save" ]]; then
        echo "Error: No command provided for 'new'." >&2
        usage
    fi

    local filename
    filename=$(echo "$command_to_save" |
        tr -s '[:space:]/' '-' |
        tr -cd 'a-zA-Z0-9-_' |
        cut -c 1-50)
    filename="${filename:-command}.json"

    if [[ -e "$filename" ]]; then
        echo "Error: File '$filename' already exists." >&2
        exit 1
    fi

    jq -n \
        --arg cmd "$command_to_save" \
        '{command: $cmd, lastResult: ""}' > "$filename"

    echo "Tracker created: $filename"
}

# Runs a tracked command, diffs the output, and updates the tracker file.
# Arguments:
#   $1: Path to the JSON tracker file.
handle_diff() {
    local json_path="$1"
    if [[ ! -f "$json_path" ]]; then
        echo "Error: Tracker file not found at '$json_path'." >&2
        exit 1
    fi

    local command_to_run
    command_to_run=$(jq -r '.command' "$json_path")
    if [[ "$command_to_run" == "null" || -z "$command_to_run" ]]; then
        echo "Error: Could not read a valid 'command' from '$json_path'." >&2
        exit 1
    fi

    local last_result
    last_result=$(jq -r '.lastResult' "$json_path")

    echo "--- Running command: $command_to_run"
    local current_result
    current_result=$(eval "$command_to_run")

    echo "--- Comparing with last run..."
    # Use process substitution to feed strings directly to diff.
    # `|| true` prevents the script from exiting if diff finds differences (exit code 1).
    diff -u --label "Last Result" <(echo "$last_result") --label "Current Result" <(echo "$current_result") || true

    # Update the JSON file safely using a temporary file.
    local temp_file
    temp_file=$(mktemp)
    jq --arg res "$current_result" '.lastResult = $res' "$json_path" > "$temp_file" && mv "$temp_file" "$json_path"

    echo "--- Tracker file '$json_path' updated."
}

# --- MAIN LOGIC ---

main() {
    check_dependencies

    if [[ $# -eq 0 ]]; then
        usage
    fi

    case "$1" in
        new)
            shift
            handle_new "$@"
            ;;
        -h|--help)
            usage
            ;;
        *)
            # If it's not a known subcommand, assume it's a file path.
            if [[ -f "$1" ]]; then
                handle_diff "$1"
            else
                echo "Error: Unknown subcommand or file not found: '$1'" >&2
                usage
            fi
            ;;
    esac
}

main "$@"
