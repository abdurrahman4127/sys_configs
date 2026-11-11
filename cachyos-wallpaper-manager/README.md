# CachyOS Plasma Wallpaper Manager

Automated random wallpaper selection on login/reboot and instant deterministic cycling via `Meta+Alt+W`.

## Directory Structure

```text
cachyos-wallpaper-manager/
├── bin/
│   ├── random-wallpaper.sh     # Runs on session start (autostart)
│   └── cycle-wallpaper.sh      # Cycles to the next wallpaper in sorted order
└── desktop-entries/
    ├── random-wallpaper.desktop # Autostart entry for random wallpaper
    └── wallpaper-cycle.desktop  # Global shortcut entry for Meta+Alt+W
```

## Quick Installation on a New Machine

**Copy scripts and make executable:**
   ```bash
   mkdir -p ~/.local/bin ~/.local/share/applications ~/.config/autostart
   cp bin/*.sh ~/.local/bin/
   chmod +x ~/.local/bin/*.sh
   ```

**Copy desktop entries:**
   ```bash
   cp desktop-entries/random-wallpaper.desktop ~/.config/autostart/
   cp desktop-entries/wallpaper-cycle.desktop ~/.local/share/applications/
   ```

**Bind the shortcut in `~/.config/kglobalshortcutsrc`:**
   Add this section to the file:
   ```ini
   [services][wallpaper-cycle.desktop]
   _launch=Meta+Alt+W
   ```

Log out and back in (or restart `kglobalaccel` / KWin).
