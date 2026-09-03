# File Content Copier

A simple, convenient script for Linux that pops up a file browser to let you select a text or code file (e.g. `.txt`, `.md`, `.html`, `.json`, `.py`, etc.) and copies its entire content to the clipboard. Designed for use with a global keyboard shortcut or directly from the terminal.

Fully compatible with **Omarchy Quattro**, generic **Wayland (using `wl-copy`)**, and **X11 (using `xclip` or `xsel`)**.

---

## Features

- **Omarchy Quattro & Wayland Native**: Integrates with Omarchy's notification system (`omarchy notification send`) and `wl-copy`.
- **Desktop Notifications**: Displays toast notifications on success or error without blocking modal dialogs.
- **Smart Window Tiling Handling**: Floats the file chooser dialog nicely in tiling window managers like Hyprland.
- **Silent Cancellation**: Cleanly exits if you cancel or press Escape, without spurious error dialogs.
- **Broad File Support**: Filter presets for Markdown, text, HTML, source code (`.js`, `.py`, `.sh`, `.json`, `.yaml`, etc.), and any file.
- **CLI & Shortcut Support**: Run with a file argument (`./copy-file-content.sh myfile.txt`) or without arguments to open the file chooser.

---

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/budiperm/file-content-copier.git
   cd file-content-copier
   ```

2. **Run the installer:**
   The installer detects your environment (Omarchy, Wayland, or X11) and installs missing dependencies (`zenity`, `wl-clipboard`, or `xclip`) via your system package manager (`omarchy`, `pacman`, `apt`, or `dnf`).
   ```bash
   ./install.sh
   ```

   > **Tip for Omarchy Quattro users**: You can run `./install.sh --configure` to automatically register the keybinding and floating window rule into your Hyprland configuration.

---

## Configuration & Usage

Assign `copy-file-content.sh` to a global keyboard shortcut in your desktop environment or window manager.

### Omarchy Quattro (Hyprland with Lua)

Omarchy Quattro configures Hyprland via Lua in `~/.config/hypr/`.

1. **Add Keybinding** in `~/.config/hypr/bindings.lua`:
   ```lua
   -- Bind CTRL + ALT + C to copy file content
   o.bind("CTRL + ALT + C", "Copy file content", "/path/to/file-content-copier/copy-file-content.sh")
   ```
   *(Check your active bindings with `omarchy menu keybindings`)*

2. **Float File Chooser Dialog** in `~/.config/hypr/hyprland.lua`:
   ```lua
   -- Ensure Zenity dialogs open floating and centered
   o.window("zenity", { tag = "+floating-window" })
   ```

3. **Reload Hyprland**:
   ```bash
   hyprctl reload
   ```

---

### Standard Hyprland (`~/.config/hypr/hyprland.conf`)

If using upstream Hyprland with `.conf` files:

```ini
# Keybinding
bind = CTRL ALT, C, exec, /path/to/file-content-copier/copy-file-content.sh

# Float dialog
windowrulev2 = float, class:^(zenity)$
```

---

### Sway / i3

In `~/.config/sway/config` or `~/.config/i3/config`:

```ini
bindsym Ctrl+Mod1+c exec /path/to/file-content-copier/copy-file-content.sh
for_window [app_id="zenity"] floating enable
for_window [class="Zenity"] floating enable
```

---

### Direct Command Line Usage

You can also pass a file directly to copy its contents immediately:

```bash
./copy-file-content.sh /path/to/document.md
```
