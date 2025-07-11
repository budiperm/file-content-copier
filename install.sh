#!/bin/bash

# A simple installer script for the "copy-file-content" tool.

echo "Starting installation for Copy-to-Clipboard script..."

# --- Helper function to check if a command exists ---
command_exists() {
    command -v "$1" &> /dev/null
}

# --- Check for a package manager and set the install command ---
INSTALL_CMD=""
if command_exists apt; then
    INSTALL_CMD="sudo apt update && sudo apt install -y"
elif command_exists dnf; then
    INSTALL_CMD="sudo dnf install -y"
elif command_exists pacman; then
    INSTALL_CMD="sudo pacman -Syu --noconfirm"
else
    echo "Error: Could not find a supported package manager (apt, dnf, pacman)."
    echo "Please install dependencies manually."
    exit 1
fi

# --- Check and install dependencies ---
dependencies=("zenity" "wl-clipboard" "xclip")
for pkg in "${dependencies[@]}"; do
    # Use the binary name to check if it's installed, but use the package name to install
    binary_name=$pkg
    if [ "$pkg" == "wl-clipboard" ]; then
        binary_name="wl-copy"
    fi

    if command_exists $binary_name; then
        echo "$pkg is already installed."
    else
        echo "Installing $pkg..."
        $INSTALL_CMD $pkg
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install $pkg. Please install it manually."
            exit 1
        fi
    fi
done

# --- Make the main script executable ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
chmod +x "$SCRIPT_DIR/copy-file-content.sh"

echo ""
echo "------------------------------------------------------"
echo "Installation complete!"
echo "The script 'copy-file-content.sh' is now executable."
echo ""
echo "To use it, bind the following command to a key:"
echo "$SCRIPT_DIR/copy-file-content.sh"
echo ""
echo "Example for hyprland.conf:"
echo "bind = CTRL ALT, C, exec, $SCRIPT_DIR/copy-file-content.sh"
echo "------------------------------------------------------"

exit 0
