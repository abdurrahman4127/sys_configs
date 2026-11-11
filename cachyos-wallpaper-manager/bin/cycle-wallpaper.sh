#!/bin/sh
# Cycle the desktop wallpaper to the next image in the CachyOS collection,
# in deterministic (LC_ALL=C sorted) order. Wraps around at the end.
# Bound to Meta+Alt+W via kglobalaccel (wallpaper-cycle.desktop).

DIR="/usr/share/wallpapers/cachyos-wallpapers"
CONF="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

# Current wallpaper (first Image= line, strip the file:// prefix).
CURRENT=$(sed -n 's|^Image=file://||p' "$CONF" 2>/dev/null | head -n 1)

# Deterministic, sorted candidate list.
LIST=$(find "$DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.bmp' \) \
        -readable 2>/dev/null | LC_ALL=C sort)

[ -n "$LIST" ] || { echo "cycle-wallpaper: no candidates in $DIR" >&2; exit 1; }

# Pick the entry after the current one; wrap to the first if at the end or
# if the current image is not in the list.
NEXT=""
FOUND=0
while IFS= read -r f; do
    if [ -n "$CURRENT" ] && [ "$f" = "$CURRENT" ]; then
        FOUND=1
        continue
    fi
    if [ "$FOUND" -eq 1 ]; then
        NEXT="$f"
        break
    fi
done <<EOF
$LIST
EOF

[ -n "$NEXT" ] || NEXT=$(printf '%s\n' "$LIST" | head -n 1)

plasma-apply-wallpaperimage "$NEXT"