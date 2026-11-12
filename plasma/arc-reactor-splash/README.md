# Arc Reactor — Plasma login splash

A custom Plasma "look-and-feel" package whose only job is to play
`arc-reactor.gif` fullscreen while the desktop loads after login.

## How it works

`ksplashqml` renders `contents/splash/Splash.qml` at login. That file is an
`AnimatedImage` with `fillMode: PreserveAspectCrop`, looping forever — no
progress bar, no logo, just the reactor. Plasma closes it when the session
reports ready (hard cap: 40 s, from `TimeoutSec=40sec` in
`/usr/lib/systemd/user/plasma-ksplash.service`).

Measured on this machine: **~5 s**, so the 1.28 s GIF loops ~4 times.

## Install

```bash
mkdir -p ~/.local/share/plasma/look-and-feel
cp -r plasma/arc-reactor-splash ~/.local/share/plasma/look-and-feel/arc-reactor
cp plasma/arc-reactor-splash/ksplashrc ~/.config/ksplashrc
```

The `ksplashrc` shipped here is:

```ini
[KSplash]
Engine=KSplashQML
Theme=arc-reactor
```

Alternatively pick **Arc Reactor** in System Settings → Colors & Themes →
Splash Screen.

The theme id comes from the folder name (`arc-reactor`) and
`KPlugin.Id` in `metadata.json`; keep them in sync.

## Preview without logging out

```bash
ksplashqml --test --window --nofork arc-reactor
```

## Revert

```ini
[KSplash]
Engine=none
Theme=None
```

or delete the folder. Nothing system-owned is modified — the theme lives
entirely in `~/.local/share` and `~/.config`.

## Notes

- Source GIF: `/usr/share/wallpapers/cachyos-wallpapers/arc-reactor.gif`
  (1920×1080, 16 frames, 1.28 s loop, 585 KB). A byte-identical copy lives in
  `contents/splash/images/`.
- AnimatedImage decodes all frames: ~133 MB RAM for the few seconds the splash
  is alive. `cache: false` avoids leaving a disk cache behind.
- This is the `ksplashqml` splash (after password), **not** Plymouth and **not**
  the greeter background. Those are separate and unchanged.
- First login after install may show a brief black frame while Qt compiles the
  QML; later logins are cached.
