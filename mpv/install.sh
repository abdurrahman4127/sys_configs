#!/usr/bin/env bash
# Install the mpv configuration, resume helpers and prune timer on a new machine.
# Safe to re-run: it overwrites the installed copies with the ones from this repo.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

install -Dm644 "$here/mpv.conf"                       "$HOME/.config/mpv/mpv.conf"
install -Dm644 "$here/input.conf"                     "$HOME/.config/mpv/input.conf"
install -Dm644 "$here/scripts/autosave-position.lua"  "$HOME/.config/mpv/scripts/autosave-position.lua"
install -Dm755 "$here/bin/mpv-wl-prune"               "$HOME/.local/bin/mpv-wl-prune"
install -Dm755 "$here/bin/mpv-wl-migrate"             "$HOME/.local/bin/mpv-wl-migrate"
install -Dm644 "$here/systemd/mpv-wl-prune.service"   "$HOME/.config/systemd/user/mpv-wl-prune.service"
install -Dm644 "$here/systemd/mpv-wl-prune.timer"     "$HOME/.config/systemd/user/mpv-wl-prune.timer"

systemctl --user daemon-reload
systemctl --user enable --now mpv-wl-prune.timer

echo
echo "Installed. Timer status:"
systemctl --user list-timers mpv-wl-prune.timer --no-pager
echo
echo "Dry run of the pruner (nothing is deleted):"
"$HOME/.local/bin/mpv-wl-prune" --dry-run
