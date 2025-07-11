# Copy to Clipboard Script

A simple, convenient script for Linux that pops up a file browser to let you select a `.txt` or `.html` file and copies its entire content to the clipboard. Designed for use with a global keyboard shortcut.

This script is environment-aware and works on both **Wayland (using `wl-copy`)** and **X11 (using `xclip`)**.

## Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/YOUR_USERNAME/filet-content-copier.git](https://github.com/YOUR_USERNAME/file-content-copier.git)
    ```

2.  **Navigate into the directory:**
    ```bash
    cd file-content-copier
    ```

3.  **Run the installer:**
    The installer will check for necessary dependencies (`zenity`, `wl-clipboard`, `xclip`) and install them using your system's package manager (supports `apt`, `dnf`, `pacman`). It will also make the main script executable.
    ```bash
    bash install.sh
    ```

## Usage

After installation, you need to assign the script to a keyboard shortcut in your desktop environment or window manager.

The command to execute is the full path to the `copy-file-content.sh` script. The installer will print the exact path for you.

#### Example for Hyprland (`~/.config/hypr/hyprland.conf`):

```ini
# Bind CTRL+ALT+C to run the copy script
bind = CTRL ALT, C, exec, /path/to/your/repo/copy-to-clipboard/copy-file-content.sh
