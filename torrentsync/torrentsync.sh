#!/usr/bin/env bash

set -u

echo
echo "╭──────────────────────────────╮"
echo "│        TorrentSync           │"
echo "╰──────────────────────────────╯"
echo

# Fixed source directories
sources=(
    "/home/rand0m"
    "/home/temp0rary"
    "/home/stuDie/sub-torrents"
)

# Fixed target directory
target="/home/ar/torrents"

# Validate source directories
for src in "${sources[@]}"; do
    if [[ ! -d "$src" ]]; then
        echo "  ✗ Source directory does not exist: $src"
        exit 1
    fi
done

# Create target directory if necessary
if [[ ! -d "$target" ]]; then
    echo "Target directory does not exist. Creating it..."
    mkdir -p "$target" || {
        echo "  ✗ Failed to create target directory: $target"
        exit 1
    }
fi

echo "Sources:"
for src in "${sources[@]}"; do
    echo "  → $src"
done

echo
echo "Target:"
echo "  → $target"

echo
read -rp "Continue? [Y/n]: " confirm

if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo
echo "Syncing..."
echo

linked=0
skipped=0
failed=0

for src in "${sources[@]}"; do
    while IFS= read -r -d '' dir; do
        name="${dir##*/}"

        [[ "$name" == ".Trash-1000" ]] && continue

        link="$target/$name"

        if [[ -e "$link" || -L "$link" ]]; then
            echo "  SKIP   $name"
            ((skipped++))
            continue
        fi

        if ln -s "$dir" "$link"; then
            echo "  LINK   $name"
            ((linked++))
        else
            echo "  FAIL   $name"
            ((failed++))
        fi

    done < <(
        find "$src" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            ! -name ".Trash-1000" \
            -print0
    )
done

echo
echo "╭──────────────────────────────╮"
echo "│           Complete           │"
echo "╰──────────────────────────────╯"
echo
echo "  Linked : $linked"
echo "  Skipped: $skipped"
echo "  Failed : $failed"
echo
