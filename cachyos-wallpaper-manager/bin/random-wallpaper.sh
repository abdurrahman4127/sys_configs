#!/bin/sh
# Pick a random wallpaper from the CachyOS collection and apply it to every
# Plasma desktop. Runs once per session (login / restart / reboot) from the
# autostart entry random-wallpaper.desktop.

DIR="/usr/share/wallpapers/cachyos-wallpapers"
CONF="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
LOG="$HOME/.local/state/random-wallpaper.log"

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG"; }

# Wait for plasmashell (autostart can fire before the shell is up).
i=0
while [ "$i" -lt 40 ]; do
    pgrep -x plasmashell >/dev/null 2>&1 && break
    i=$((i + 1))
    sleep 1
done

# Build the candidate list (any supported image, including animated GIFs).
LIST=$(find "$DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.bmp' \) \
        -readable 2>/dev/null)

if [ -z "$LIST" ]; then
    log "no images found in $DIR"
    exit 1
fi

# Avoid repeating the wallpaper that is already set.
CURRENT=$(sed -n 's|^Image=file://||p' "$CONF" 2>/dev/null | head -n 1)
if [ -n "$CURRENT" ]; then
    FILTERED=$(printf '%s\n' "$LIST" | grep -vxF -- "$CURRENT")
    [ -n "$FILTERED" ] && LIST="$FILTERED"
fi

IMG=$(printf '%s\n' "$LIST" | shuf -n 1)

# Apply, retrying while plasmashell finishes starting.
i=0
while [ "$i" -lt 20 ]; do
    if plasma-apply-wallpaperimage "$IMG" >>"$LOG" 2>&1; then
        log "set $IMG"
        exit 0
    fi
    i=$((i + 1))
    sleep 2
done

log "failed to apply $IMG"
exit 1
