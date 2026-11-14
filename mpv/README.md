# mpv configuration — resume that survives reboots, symlinks and renames

This directory is the source of truth for the mpv setup on this machine. It fixes two
long-standing annoyances and keeps the resume cache bounded:

1. **Resume stopped working after a reboot** — the same video started from `0:00` even
   though it resumed fine when reopened in the same session.
2. **`watch_later` grew forever** — 734 files, most pointing at videos that had been
   deleted, renamed or moved months ago.

Everything here is reproducible from a clean install with `./install.sh`; see
[Install](#install--reproduce).

---

## 1. How mpv resume actually works (the part that explains the bugs)

All of this was confirmed against **mpv 0.41.0** source (`player/configfiles.c`,
`player/loadfile.c`, `misc/path_utils.c`) and by experiment on this machine.

### State location

```
${XDG_STATE_HOME:-$HOME/.local/state}/mpv/watch_later/
```

One small file per resume slot. Older mpv releases (and therefore most guides) used
`~/.config/mpv/watch_later/` instead — check with
`mpv --list-options | grep watch-later-dir` if in doubt.

### The key is the path, not the file

```c
// player/configfiles.c
if (mp_is_url(bstr0(fname)))            path = fname;                      // URL kept verbatim
else if (opts->ignore_path_in_watch_later_config) path = mp_basename(fname); // filename only
else                                    path = mp_normalize_path(tmp, fname);
md5(path) -> uppercase hex -> filename in watch_later/
```

`mp_normalize_path()` makes the path absolute, collapses `//`, `.` and `..` (only a `..`
triggers `realpath()`), and otherwise **never resolves symlinks**. Consequences:

| Route to the same file | watch-later key |
|---|---|
| `/home/temp0rary/[x] VisionQuest.S01/E02.mkv` | `07FC8BA5…` |
| `/home/ar/torrents/[x] VisionQuest.S01/E02.mkv` (symlink) | `F89A14E0…` |
| same file after a folder rename | a third key |
| same file copied to another disk | a fourth key |

So a video can own as many resume slots as it has path spellings, and only the exact
spelling used at save time can find its position. This was the reboot bug: the file is
opened through a different route after a reboot, so the key misses and playback starts at
`0:00` while the old entry sits on disk unused.

### When mpv writes the position

Only two moments, unless something tells it otherwise:

* on quit, when `save-position-on-quit=yes`;
* when the `loadfile` command replaces the current playlist (manual: *"Always save the
  current playback position on quit, and also when the `loadfile` command is used to
  replace the current playlist"*).

Nothing else. A reboot, power loss, `SIGKILL`, a hung NTFS read or a crash between those
events loses everything since the last write.

Worse, the entry is **consumed**: right after a successful load *with* a resume entry, mpv
deletes it (`player/loadfile.c`, `mp_delete_watch_later_conf()`) and rewrites it on quit.
If the process is killed after resuming but before quitting normally, the position is gone
entirely.

### Redirect entries

`write_redirects_for_parent_dirs()` writes a `# redirect entry` file for every parent
directory of the played file, and it also **deletes** entries for those parents when a
directory is played/expanded. These are not positions — they make `mpv /some/folder`
resume the right episode. They are skipped when filename-only keys are enabled.

### Other options that matter

| Option | Default | Notes |
|---|---|---|
| `resume-playback` | yes | enables reading the entry |
| `resume-playback-check-mtime` | **no** | so a changed mtime never invalidates a resume |
| `save-position-on-quit` | no | what this config enables |
| `write-filename-in-watch-later-config` | no | prepends `# <path>` (or `# <basename>`) to each entry |
| `ignore-path-in-watch-later-config` | no | keys on filename only |
| `watch-later-options` | long list | which options are stored; `start` is the position |

---

## 2. What was changed

### `mpv.conf`

```ini
save-position-on-quit=yes
keep-open=yes

ignore-path-in-watch-later-config=yes
write-filename-in-watch-later-config=yes
script-opts=autosave-position-interval=10
```

* `ignore-path-in-watch-later-config=yes` — resume key becomes `md5(basename)`.
  Symlinks, `[x] ` renames and moves between the three NTFS disks all resolve to the same
  slot. Collision risk was measured before enabling: **0 duplicate filenames across 440
  videos** (no `sample.mkv`-style generic names either).
* `write-filename-in-watch-later-config=yes` — every entry starts with `# <filename>`, so
  entries are self-documenting and `g-w` (watch-later picker) is usable. It also makes
  migrations and audits possible, which was impossible before.
* `script-opts=…` — configures the autosave script below (10 s).

### `scripts/autosave-position.lua` → `~/.config/mpv/scripts/`

Calls `write-watch-later-config` every 10 seconds while a file is playing (configurable,
`0` disables). Skips idle, EOF and unchanged positions. This is the safety net for every
abnormal exit: after a hard reboot/crash/`SIGKILL` at most 10 s of progress is lost.

Validated: `seek 50`, `SIGKILL` → entry contains `start=51.833`.

### `bin/mpv-wl-prune` → `~/.local/bin/` + user timer

**Policy: age-based, 14 days.** Any entry whose mtime is older than `MPV_WL_RETENTION_DAYS`
(default 14) is deleted, whether or not the video still exists. mtime is refreshed every
time mpv saves that video's position (including each autosave), so this keeps roughly the
last two weeks of activity and nothing else.

```
mpv-wl-prune [-n|--dry-run] [-h|--help]
MPV_WL_RETENTION_DAYS=30 mpv-wl-prune     # override retention
```

* `systemd/mpv-wl-prune.service` — `Type=oneshot`, runs the script.
* `systemd/mpv-wl-prune.timer` — `OnCalendar=daily`, `Persistent=true` (a missed day runs
  at next boot), `RandomizedDelaySec=1h` (no midnight thundering herd).

Age is used instead of "does the file exist" on purpose: the entry filename is an MD5 and
cannot be reversed. Even with filename comments present, a path check would be unsafe
(unmounted NTFS disks look like deleted files).

One-time result on this machine: **734 → 97 files** (2.9 KB), oldest 2026-11-01.

### `bin/mpv-wl-migrate` → `~/.local/bin/` (one-off tool)

After switching to filename-only keys, old path-keyed entries are unreachable. This tool
reconstructs the original path for entries whose file still exists (matching real paths,
`[x] `-stripped variants and the old capital-T `Torrents` path), rewrites them under the
filename key and deletes the old entry. Entries whose file is gone are unrecoverable and
are left for the pruner.

Run once when enabling the new key mode:

```
mpv-wl-migrate --dry-run
mpv-wl-migrate
```

Result on this machine: 2 entries recovered (12 Monkeys S02E13, Dirk Gently S01E03), e.g.
Holistic resumed at `00:24:32` when opened through the *symlink* path even though it was
saved through the real path.

---

## 3. Install / reproduce

Prerequisites: `mpv` (0.41 tested), `systemd` user session, `python3` only for the one-off
migration tool.

```bash
git clone https://github.com/abdurrahman4127/sys_configs
cd sys_configs/mpv
./install.sh
```

`install.sh` copies every file to its destination, reloads systemd, enables the timer and
prints a dry run. Manual equivalent:

```bash
install -Dm644 mpv.conf                      ~/.config/mpv/mpv.conf
install -Dm644 input.conf                    ~/.config/mpv/input.conf
install -Dm644 scripts/autosave-position.lua ~/.config/mpv/scripts/autosave-position.lua
install -Dm755 bin/mpv-wl-prune              ~/.local/bin/mpv-wl-prune
install -Dm755 bin/mpv-wl-migrate            ~/.local/bin/mpv-wl-migrate
install -Dm644 systemd/mpv-wl-prune.service  ~/.config/systemd/user/mpv-wl-prune.service
install -Dm644 systemd/mpv-wl-prune.timer    ~/.config/systemd/user/mpv-wl-prune.timer
systemctl --user daemon-reload
systemctl --user enable --now mpv-wl-prune.timer
```

If migrating an existing machine: restart mpv first (options are read at startup), then run
`mpv-wl-migrate` and finally `mpv-wl-prune --dry-run`.

---

## 4. Verify

```bash
# 1. options are really applied
mpv -v --frames=0 /usr/share/sounds/freedesktop/stereo/bell.oga 2>&1 |
    grep -E "ignore-path-in-watch-later-config|save-position-on-quit|autosave"

# 2. an entry is filename-keyed and self-describing
head -1 ~/.local/state/mpv/watch_later/*          # prints "# <filename>" lines

# 3. resume through a different path spelling works
mpv --frames=1 --no-save-position-on-quit \
    --term-playing-msg='RESUMED_AT=${time-pos}' \
    "/home/ar/torrents/[x] <show>/<episode>.mkv"

# 4. autosave survives a hard kill
mpv --vo=null --ao=null --script=~/.config/mpv/scripts/autosave-position.lua \
    --script-opts=autosave-position-interval=2 --watch-later-dir=/tmp/wl-test <file> &
sleep 5; kill -9 $!; cat /tmp/wl-test/*

# 5. pruner
mpv-wl-prune --dry-run

# 6. timer
systemctl --user list-timers mpv-wl-prune.timer
journalctl --user -u mpv-wl-prune.service
```

---

## 5. Caveats / trade-offs

* **Filename collisions.** Two different files with the same basename share one position.
  Measured 0 collisions in the current library. Re-check after adding large batches:
  ```bash
  find /home/ar/torrents /home/temp0rary /home/rand0m /home/stuDie -type f \
       \( -name '*.mkv' -o -name '*.mp4' \) -printf '%f\n' | sort | uniq -d
  ```
* **Directory-mode resume is gone.** With filename-only keys mpv no longer writes redirect
  entries for parent folders, so `mpv /some/folder` cannot resume the last episode that
  way. Opening individual files is unaffected.
* **14-day retention is by design.** A video paused more than 14 days ago loses its
  position. Use `MPV_WL_RETENTION_DAYS` if that is too aggressive.
* **Streams.** URL entries are keyed by the full URL (the filename option does not apply),
  so ephemeral `yt-dlp -g` / signed links still mint a new entry per URL. Unseekable
  streams never store a position (`Not seekable, or time unknown`).
* **`keep-open=yes`.** A finished video keeps its last frame; quitting there stores the end
  position. The autosave script skips EOF so it does not pin the resume point itself.
* **Running instances ignore new options.** mpv reads `mpv.conf` at startup; restart it
  after changing the config.

---

## 6. Rollback

```bash
systemctl --user disable --now mpv-wl-prune.timer
rm -f ~/.config/systemd/user/mpv-wl-prune.{service,timer}
rm -f ~/.local/bin/mpv-wl-prune ~/.local/bin/mpv-wl-migrate
rm -f ~/.config/mpv/scripts/autosave-position.lua
# then from mpv.conf remove: ignore-path…, write-filename…, script-opts=autosave…
```

Old path-keyed entries were pruned/pruned-by-age; restoring them is not possible, but
filename-keyed entries keep working as long as `ignore-path-in-watch-later-config=yes`
stays enabled.

---

## 7. Layout

```
mpv/
├── mpv.conf                        # installed to ~/.config/mpv/mpv.conf
├── input.conf                      # installed to ~/.config/mpv/input.conf
├── scripts/
│   └── autosave-position.lua       # ~/.config/mpv/scripts/
├── bin/
│   ├── mpv-wl-prune                # ~/.local/bin/  (timer calls this)
│   └── mpv-wl-migrate              # ~/.local/bin/  (one-off)
├── systemd/
│   ├── mpv-wl-prune.service
│   └── mpv-wl-prune.timer
├── install.sh
└── README.md
```
