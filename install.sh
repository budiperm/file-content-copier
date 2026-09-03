#!/usr/bin/env bash

# A smart installer script for the "file-content-copier" tool.
# Fully compatible with Omarchy Quattro (Hyprland / Lua), Arch Linux, Fedora, Debian/Ubuntu, and X11/Wayland.

set -e

echo "Starting installation for File Content Copier..."

command_exists() {
    command -v "$1" &> /dev/null
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/copy-file-content.sh"

# Ensure main script is executable
chmod +x "$MAIN_SCRIPT"

# --- Detect Environment ---
IS_OMARCHY=false
if command_exists omarchy || [ -d "/usr/share/omarchy" ]; then
    IS_OMARCHY=true
fi

IS_WAYLAND=false
if [ -n "${WAYLAND_DISPLAY:-}" ] || [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ "$IS_OMARCHY" = true ]; then
    IS_WAYLAND=true
fi

echo "Environment detected: $( [ "$IS_OMARCHY" = true ] && echo "Omarchy / " )$( [ "$IS_WAYLAND" = true ] && echo "Wayland" || echo "X11" )"

# --- Determine Required Dependencies ---
declare -a NEEDED_PKGS=()

if ! command_exists zenity; then
    NEEDED_PKGS+=("zenity")
fi

if [ "$IS_WAYLAND" = true ]; then
    if ! command_exists wl-copy; then
        NEEDED_PKGS+=("wl-clipboard")
    fi
else
    if ! command_exists xclip && ! command_exists xsel; then
        NEEDED_PKGS+=("xclip")
    fi
fi

# Check for notification tool on non-Omarchy systems (Omarchy has built-in omarchy notification send)
if [ "$IS_OMARCHY" = false ] && ! command_exists notify-send; then
    NEEDED_PKGS+=("libnotify")
fi

# --- Install Missing Packages ---
if [ ${#NEEDED_PKGS[@]} -gt 0 ]; then
    echo "Missing dependencies to install: ${NEEDED_PKGS[*]}"

    if [ "$IS_OMARCHY" = true ] && command_exists omarchy; then
        echo "Installing packages using Omarchy package manager (omarchy pkg add)..."
        omarchy pkg add "${NEEDED_PKGS[@]}"
    elif command_exists pacman; then
        echo "Installing packages using pacman..."
        sudo pacman -S --needed --noconfirm "${NEEDED_PKGS[@]}"
    elif command_exists apt; then
        echo "Installing packages using apt..."
        sudo apt update && sudo apt install -y "${NEEDED_PKGS[@]}"
    elif command_exists dnf; then
        echo "Installing packages using dnf..."
        sudo dnf install -y "${NEEDED_PKGS[@]}"
    else
        echo "Error: Supported package manager not found (omarchy, pacman, apt, dnf)."
        echo "Please install the following packages manually: ${NEEDED_PKGS[*]}"
        exit 1
    fi
else
    echo "All core dependencies (zenity, clipboard provider) are already installed."
fi

# --- Omarchy Quattro / Hyprland Setup Assistant ---
HYPR_BINDINGS_LUA="$HOME/.config/hypr/bindings.lua"
HYPR_MAIN_LUA="$HOME/.config/hypr/hyprland.lua"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

LUA_BINDING="o.bind(\"CTRL + ALT + C\", \"Copy file content\", \"$MAIN_SCRIPT\")"
LUA_WINDOW_RULE="o.window(\"zenity\", { tag = \"+floating-window\" })"

echo ""
echo "======================================================"
echo "Installation complete!"
echo "The script 'copy-file-content.sh' is executable."
echo "======================================================"

# If Omarchy Quattro Lua configuration is detected:
if [ -f "$HYPR_BINDINGS_LUA" ]; then
    echo ""
    echo "Omarchy Quattro detected! (~/.config/hypr/bindings.lua found)"
    echo ""
    echo "1. Recommended Keybinding in ~/.config/hypr/bindings.lua:"
    echo "   $LUA_BINDING"
    echo ""
    echo "2. Recommended Floating Window Rule in ~/.config/hypr/hyprland.lua:"
    echo "   $LUA_WINDOW_RULE"
    echo ""

    if grep -q "copy-file-content.sh" "$HYPR_BINDINGS_LUA" 2>/dev/null; then
        echo "-> Keybinding is already present in $HYPR_BINDINGS_LUA"
    else
        AUTO_ADD=false
        for arg in "$@"; do
            if [ "$arg" = "--configure" ] || [ "$arg" = "-y" ] || [ "$arg" = "--yes" ]; then
                AUTO_ADD=true
            fi
        done

        if [ "$AUTO_ADD" = false ] && [ -t 0 ]; then
            read -r -p "Would you like to automatically add this keybinding and window rule to your Omarchy config? [y/N] " response
            case "$response" in
                [yY][eE][sS]|[yY])
                    AUTO_ADD=true
                    ;;
            esac
        fi

        if [ "$AUTO_ADD" = true ]; then
            echo "Adding keybinding to $HYPR_BINDINGS_LUA..."
            cp "$HYPR_BINDINGS_LUA" "$HYPR_BINDINGS_LUA.bak.$(date +%s)"
            printf "\n-- Copy file content shortcut\n%s\n" "$LUA_BINDING" >> "$HYPR_BINDINGS_LUA"

            if [ -f "$HYPR_MAIN_LUA" ] && ! grep -q 'o.window("zenity"' "$HYPR_MAIN_LUA" 2>/dev/null; then
                echo "Adding floating rule for zenity to $HYPR_MAIN_LUA..."
                cp "$HYPR_MAIN_LUA" "$HYPR_MAIN_LUA.bak.$(date +%s)"
                printf "\n-- Zenity file dialog floating rule\n%s\n" "$LUA_WINDOW_RULE" >> "$HYPR_MAIN_LUA"
            fi

            if command_exists hyprctl; then
                hyprctl reload >/dev/null 2>&1 || true
                echo "Hyprland reloaded successfully!"
            fi
        fi
    fi
elif [ -f "$HYPR_CONF" ]; then
    echo ""
    echo "Standard Hyprland detected! Add to ~/.config/hypr/hyprland.conf:"
    echo "bind = CTRL ALT, C, exec, $MAIN_SCRIPT"
    echo "windowrulev2 = float, class:^(zenity)$"
else
    echo ""
    echo "To use this script, bind the following command to a global shortcut:"
    echo "$MAIN_SCRIPT"
fi

echo "======================================================"
exit 0
