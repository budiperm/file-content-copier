#!/bin/bash

# --- Determine which copy command to use ---
COPY_CMD=""
if command -v wl-copy &> /dev/null; then
    COPY_CMD="wl-copy"
elif command -v xclip &> /dev/null; then
    COPY_CMD="xclip -selection clipboard"
else
    zenity --error --text="Error: Neither wl-copy nor xclip is installed." --title="Dependency Missing" --timeout=3 2>/dev/null
    exit 1
fi

# --- Show file selection dialog with filters ---
SELECTED_FILE=$(zenity --file-selection --title="Select a Text or HTML File" \
    --file-filter="Text and HTML files | *.txt *.html" \
    --file-filter="All files | *" 2>/dev/null)

# --- Check selection and copy the content ---
if [ -f "$SELECTED_FILE" ] && $COPY_CMD < "$SELECTED_FILE"; then
    # Success notification
    zenity --info --text="File content successfully copied." --title="Success" --timeout=2 2>/dev/null
else
    # Failure notification
    zenity --error --text="File copy failed or was cancelled." --title="Failure" --timeout=2 2>/dev/null
fi

exit 0
