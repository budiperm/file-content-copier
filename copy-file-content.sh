#!/usr/bin/env bash

# Exit immediately on unset variables
set -u

# --- Notification helper (supports Omarchy Quattro, notify-send, and zenity) ---
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-low}"
    local glyph="${4:-󰅍}"

    if command -v omarchy-notification-send &>/dev/null; then
        omarchy-notification-send -u "$urgency" -g "$glyph" "$title" "$message"
    elif command -v omarchy &>/dev/null && omarchy notification send --help &>/dev/null 2>&1; then
        omarchy notification send "$title" "$message" -u "$urgency" -g "$glyph"
    elif command -v notify-send &>/dev/null; then
        local icon="dialog-information"
        [[ "$urgency" == "critical" ]] && icon="dialog-error"
        notify-send -u "$urgency" -i "$icon" -a "File Content Copier" "$title" "$message"
    elif command -v zenity &>/dev/null; then
        if [[ "$urgency" == "critical" ]]; then
            zenity --error --title="$title" --text="$message" --timeout=2 2>/dev/null
        else
            zenity --info --title="$title" --text="$message" --timeout=1 2>/dev/null
        fi
    fi
}

# --- Determine which copy command to use ---
COPY_CMD=""
if command -v wl-copy &>/dev/null; then
    COPY_CMD="wl-copy"
elif command -v xclip &>/dev/null; then
    COPY_CMD="xclip -selection clipboard"
elif command -v xsel &>/dev/null; then
    COPY_CMD="xsel --clipboard --input"
else
    notify "Dependency Missing" "Error: Neither wl-copy, xclip, nor xsel is installed." "critical" "󰅙"
    exit 1
fi

# --- File Selection ---
SELECTED_FILE=""

# If a file path was passed as an argument, use it directly
if [[ $# -gt 0 ]]; then
    if [[ -f "$1" ]]; then
        SELECTED_FILE="$1"
    else
        notify "File Not Found" "The file '$1' does not exist." "critical" "󰅙"
        exit 1
    fi
else
    # Show file selection dialog
    if command -v zenity &>/dev/null; then
        SELECTED_FILE=$(zenity --file-selection \
            --title="Select File to Copy Content" \
            --file-filter="Text & Code files | *.txt *.html *.htm *.md *.json *.lua *.sh *.bash *.py *.js *.ts *.css *.yml *.yaml *.toml *.conf *.ini *.xml *.csv *.sql" \
            --file-filter="Plain text (*.txt) | *.txt" \
            --file-filter="Markdown (*.md) | *.md" \
            --file-filter="HTML files (*.html, *.htm) | *.html *.htm" \
            --file-filter="All files | *" 2>/dev/null)
    elif command -v omarchy-menu-file &>/dev/null; then
        SELECTED_FILE=$(omarchy-menu-file "Select file to copy" "$HOME" "txt html md py sh json lua conf toml yml yaml")
    else
        notify "Dialog Missing" "Neither zenity nor omarchy menu file is available." "critical" "󰅙"
        exit 1
    fi
fi

# If user cancelled selection (empty string), exit cleanly without error
if [[ -z "$SELECTED_FILE" ]]; then
    exit 0
fi

# --- Validate and Copy Content ---
if [[ ! -f "$SELECTED_FILE" || ! -r "$SELECTED_FILE" ]]; then
    FILENAME=$(basename "$SELECTED_FILE")
    notify "Copy Failed" "Cannot read file '$FILENAME'." "critical" "󰅙"
    exit 1
fi

FILENAME=$(basename "$SELECTED_FILE")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
HTML_CONVERTER="$SCRIPT_DIR/html_to_text.py"

# If python3 and our HTML converter are available, use smart HTML detection
if command -v python3 &>/dev/null && [[ -x "$HTML_CONVERTER" ]]; then
    CONTENT=$(python3 "$HTML_CONVERTER" "$SELECTED_FILE")
    CONVERTED=$?
    if [[ $CONVERTED -eq 0 ]] && printf '%s' "$CONTENT" | $COPY_CMD; then
        # Check if the file was actually HTML (for notification message)
        if python3 "$HTML_CONVERTER" --check-html "$SELECTED_FILE" 2>/dev/null; then
            notify "File Copied" "Copied '$FILENAME' as clean text (HTML converted)." "low" "󰅍"
        else
            notify "File Copied" "Copied content of '$FILENAME' to clipboard." "low" "󰅍"
        fi
        exit 0
    else
        notify "Copy Failed" "Failed to copy content of '$FILENAME'." "critical" "󰅙"
        exit 1
    fi
else
    # Fallback: copy raw file content (original behavior)
    if $COPY_CMD < "$SELECTED_FILE"; then
        notify "File Copied" "Copied content of '$FILENAME' to clipboard." "low" "󰅍"
        exit 0
    else
        notify "Copy Failed" "Failed to copy content of '$FILENAME'." "critical" "󰅙"
        exit 1
    fi
fi
