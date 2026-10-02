#!/usr/bin/env bash

set -u

echo
echo "╭──────────────────────────────╮"
echo "│        TorrentSync           │"
echo "╰──────────────────────────────╯"
echo

sources=()

while true; do
    read -rp "Source directory: " src

    src="${src%/}"

    if [[ -z "$src" ]]; then
        echo "  ✗ Directory cannot be empty."
        continue
    fi

    if [[ ! -d "$src" ]]; then
        echo "  ✗ Directory does not exist: $src"
        continue
    fi

    sources+=("$src")

    read -rp "Add another source? [Y/n]: " another

    if [[ "$another" =~ ^[Nn]$ ]]; then
        break
    fi

    echo
done

echo

while true; do
    read -rp "Target directory: " target

    target="${target%/}"

    if [[ -z "$target" ]]; then
        echo "  ✗ Target cannot be empty."
        continue
    fi

    if [[ ! -d "$target" ]]; then
        read -rp "  Directory doesn't exist. Create it? [Y/n]: " create

        if [[ ! "$create" =~ ^[Nn]$ ]]; then
            mkdir -p "$target" || {
                echo "  ✗ Failed to create target directory."
                exit 1
            }
        else
            continue
        fi
    fi

    break
done

echo
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
