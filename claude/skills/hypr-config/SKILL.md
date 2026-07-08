---
name: hypr-config
description: "Expert guide for artur's Hyprland + Quickshell desktop on CachyOS (Arch), config at ~/.config/hypr. Use this skill whenever working on the user's Hyprland setup, Quickshell shell/bar/widgets/settings UI, cursor/wallpaper/keybind/monitor/favorites config, matugen theming, or syncing/backing up the config to the GitHub fork. Triggers on: hyprland, hypr, quickshell, qs, the settings popup, topbar, widgets, cursor theme, wallpaper picker, matugen colors, .config/hypr, or 'my config/dotfiles'."
---

# Hyprland + Quickshell desktop (artur @ CachyOS)

The user runs **CachyOS (Arch-based)**, not NixOS. Hyprland + **Quickshell**. Live config at
`~/.config/hypr/`. It's adapted from [ilyamiro/nixos-configuration](https://github.com/ilyamiro/nixos-configuration)
but edited directly as plain files — **there is no `/etc/nixos` and Nix is not used here.**

## Golden rules (read first)

1. **NEVER hand-edit `~/.config/hypr/config/*.conf`** (env.conf, settings.conf, autostart.conf,
   keybindings.conf, monitors.conf). They are **regenerated from `~/.config/hypr/templates/*.template`
   by `~/.config/hypr/scripts/settings_watcher.sh`** whenever settings change. Edit the *template* or the
   source of truth (`settings.json`) instead. `hyprland.conf`, `colors.conf`, `hyprlauncher.conf`,
   `hypridle.conf` are static and safe to edit.
2. **NEVER commit `scripts/quickshell/calendar/.env`** — it holds a live OpenWeather API key. It is
   gitignored in the fork; keep it that way. Scan staged content for secrets before any push.
3. **Always back up a QML file before editing** (`cp X.qml X.qml.bak-<feature>`), then validate
   (see Validation). The settings UI is the user's live desktop — a broken QML breaks their shell.
4. **Persisted runtime values are in `~/.config/hypr/settings.json`** (read/written by `Config.qml`
   via `jq`). `default_settings.json` is the seed/defaults. Don't confuse the two.

## Architecture

- **Quickshell QML** lives in `~/.config/hypr/scripts/quickshell/`.
  - `Shell.qml` — entry point (launched via `quickshell -p .../Shell.qml`).
  - `Config.qml` — **singleton** holding all settings. Reads/writes `settings.json` with `jq`.
    Helpers: `Config.sh(cmd)` (detached bash), `getSetting/setSetting`, `updateJsonBulk`,
    `saveAppSettings()`, plus typed properties (`uiScale`, `workspaceCount`, `favoritesData`,
    `cursorTheme`, `cursorSize`, …). To add a setting: add a property, map it in the `settingsReader`
    StdioCollector, add it to the relevant `save*` configObj.
  - `Caching.qml` — cache dir helpers (`Config` uses it for `cacheDir`).
  - `settings/SettingsPopup.qml` — the big (~4800-line) settings GUI. Tabs:
    `["General","Weather","Keybinds","Monitors","Startup","Favorites"]` (`root.currentTab`).
    Each tab is a `Component` (`generalTabComponent`, `weatherTabComponent`, …) loaded by a Loader.
  - Widget dirs: `applauncher/`, `wallpaper/`, `music/`, `network/`, `calendar/`, `clipboard/`,
    `battery/`, `focustime/`, `volume/`, `notifications/`, `updater/`, `monitors/`, `guide/`,
    `quickactions/`, `stewart/`, `movies/`, `watchers/`. Each typically pairs a `*.qml` with
    `*.sh`/`*.py` backend helpers.
- **Theming is dynamic via matugen** → writes `~/.cache/matugen/` and `colors.conf`/`qs_colors.json`.
  Changing wallpaper re-runs matugen (`wallpaper/matugen_reload.sh`).

## UI conventions in QML (match these when adding widgets)

- **Scale everything with `root.s(px)`** (UI-scale aware). Never hardcode raw pixels.
- **Theme colors** are `root.<name>`: `base, text, subtext0, surface0/1/2, mauve, pink, teal,
  peach, yellow, red, blue, sapphire, green, lavender`. Use `Qt.alpha(color, a)` for transparency.
- **Fonts**: "Inter" (UI text), "JetBrains Mono" (numbers), "Iosevka Nerd Font" (glyph icons).
- **Card pattern** in settings: a `Rectangle` "box" with `radius: root.s(12)`, `surface0` bg,
  `surface1` border, hover/active accent color, `Behavior on color { ColorAnimation … }`.
- **General-tab keyboard nav** uses `root.highlightedBox` indices **0–6** (0 guide, 1 help icon,
  2 UI scale, 3 lang, 4 layout, 5 wallpaper dir, 6 workspaces). `maxHighlightForTab(0)===6`.
  If you add a General box and want it in keyboard nav you must renumber + bump these; otherwise
  **append it at the end and keep it out of the highlight system** (this is what the Cursor box does).

## settings.json shape (live state)

Keys include: `uiScale`, `openGuideAtStartup`, `topbarHelpIcon`, `workspaceCount`, `wallpaperDir`,
`language`, `kbOptions`, `cursorTheme`, `cursorSize`, `monitors[]`, `keybinds[]`, `startup[]`,
`favorites[]` (`{name, icon, exec}`). Editing favorites/keybinds is normally done through the
settings UI, which calls `Config.saveAll*` → writes back to `settings.json`.

## The Cursor feature (reference example of a full addition)

`scripts/quickshell/cursor/`:
- `render_cursor.py` — parses the **Xcursor binary format** and renders a preview PNG via **Pillow**
  (needed because `xcur2png` isn't installed and ImageMagick can't read Xcursor).
- `cursor_manager.sh` — `list [size]` (JSON of installed themes + preview pngs), `apply <theme> <size>`,
  `import` (zenity archive picker → extracts to `~/.local/share/icons`).
- UI: a "Cursor" card at the bottom of the **General** tab (preview gallery + size stepper + Import).
- `Config.applyCursor(theme,size)` applies live and persists.
- **Persistence (multi-surface)**: `gsettings` (GTK), `~/.icons/default/index.theme` (XWayland),
  `hyprctl setcursor`/`setenv` (live), and a dedicated `~/.config/hypr/config/cursor.conf` sourced
  from `hyprland.conf` — kept out of the templated `env.conf` on purpose.
- Installed cursor themes are scanned from `~/.icons`, `~/.local/share/icons`, `/usr/share/icons`.

## settings_watcher.sh (config regeneration daemon)

- Watches `settings.json` (and calendar `.env`) via `inotifywait -m`. On a settings.json write it
  runs `compile_settings`, which regenerates `config/*.conf` from templates and `hyprctl reload`s
  **only if** a generated conf's content actually changed (md5 hash guard, split monitor vs non-monitor).
- **Runtime-only keys must never reach a reload.** It keys reloads off `relevant_hash()` — an md5 of
  ONLY `{language,kbOptions,wallpaperDir,openGuideAtStartup,startup,keybinds,monitors,hardwareEnvs}`
  (cached at `~/.cache/settings_watcher/relevant.hash`). Favorites/cursor/uiScale/topbarHelpIcon/weather
  writes leave that hash unchanged → compile is skipped entirely. This is what stops a favorite-toggle
  from re-applying monitors (the old "monitors fall apart" bug, caused by monitors.conf drift, e.g.
  a stored `@75` vs a panel's real 74Hz).
- **Restarting the watcher safely** (edits only take effect on restart; it's launched at login via
  autostart): NEVER `pkill -f settings_watcher.sh` from a shell whose own command line contains that
  string — pkill matches your own shell and kills it mid-script. Use `pgrep -f '[s]ettings_watcher.sh'`
  / explicit PIDs, seed the cache first (`relevant_hash > ~/.cache/settings_watcher/relevant.hash`),
  then relaunch detached: `setsid -f bash ~/.config/hypr/scripts/settings_watcher.sh`.
- Note: the running Quickshell also spawns its own `inotifywait …settings.json` watchers — those are
  the shell's, not the daemon's; leave them (a Quickshell reload clears them).

## Applying / reloading changes

- Reload Hyprland + shell: `~/.config/hypr/scripts/reload.sh` (or the user's Super+R bind).
- Live Hyprland tweaks: `hyprctl keyword …`, `hyprctl setcursor …`, `hyprctl setenv …`.
- Restart just Quickshell: kill it and re-run `quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml`.
  Prefer `reload.sh` to avoid flashing the bar unexpectedly — warn the user it will redraw.

## Validation (run before declaring done)

- QML: `qmllint <file>.qml` (ignore unresolved Quickshell import warnings; look for Parse/Syntax errors).
- Bash: `bash -n script.sh`. Python: `python3 -m py_compile file.py`.
- Available tools here: `quickshell`, `qmllint`, `qml`, `gsettings`, `hyprctl`, `jq`, `zenity`/`yad`/
  `kdialog`, `convert`/`magick`, `python3` + Pillow, `tar`, `unzip`. **Not installed:** `gh`, `xcur2png`.

## Backup / fork workflow

- Fork: **github.com/artur-sorokolit/nixos-configuration** (forked from ilyamiro/nixos-configuration),
  cloned at `~/nixos-configuration`. SSH push works as GitHub user `artur-sorokolit` (key
  `~/.ssh/id_ed25519`). `gh` is NOT installed — create forks/repos via the web UI.
- **Path mapping:** live `~/.config/hypr/`  ⇄  repo `config/sessions/hyprland/`.
- To sync local changes up to the fork:
  ```bash
  cd ~/nixos-configuration
  rsync -a --exclude='.env' --exclude='*.bak' --exclude='*.bak-cursor' \
    --exclude='settings.json.bak' --exclude='__pycache__' --exclude='__pycache__/**' \
    ~/.config/hypr/ config/sessions/hyprland/
  git add -A && git status --short | grep -i '\.env' && echo "ABORT: secret staged" # must print nothing
  git commit -m "sync: <what changed>

  Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  git push origin master
  ```
  Sync is **additive** (no `--delete`) so the upstream Nix scaffolding (`default.nix`, `home.nix`, etc.)
  is preserved. Pull upstream updates by adding the `upstream` remote if needed.

## How to improve this config (workflow)

1. Find the relevant widget dir under `scripts/quickshell/` (and its `.sh`/`.py` backend).
2. Back up the file(s) you'll edit. Make surgical, additive edits matching the conventions above.
3. Test backend scripts standalone first (e.g. run the `.sh`/`.py` and inspect JSON output).
4. Validate (qmllint / bash -n / py_compile).
5. Reload and confirm with the user before pushing. Then sync to the fork (above).
6. Keep the memory file `hypr-quickshell-desktop.md` and this skill updated when structure changes.
