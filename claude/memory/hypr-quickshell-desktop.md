---
name: hypr-quickshell-desktop
description: "User's Hyprland + Quickshell desktop on CachyOS, config layout and conventions"
metadata: 
  node_type: memory
  type: project
  originSessionId: ab94f0ff-1da1-405a-aae7-db8d7f045774
---

User runs **CachyOS (Arch-based)** with a Hyprland + **Quickshell** desktop, config at `~/.config/hypr/`. It is adapted from github.com/ilyamiro/nixos-configuration (a NixOS config) but runs on Arch, not Nix — so there is no `/etc/nixos`; files are edited directly.

**There is a dedicated skill** `~/.claude/skills/hypr-config/SKILL.md` with the full working guide (architecture, conventions, validation, fork-sync workflow) — it auto-loads when working on this config. Keep it updated as the structure evolves.

Key conventions:
- Quickshell QML lives in `~/.config/hypr/scripts/quickshell/`. `Config.qml` is a singleton holding settings (reads/writes `~/.config/hypr/settings.json` via `jq`). `settings/SettingsPopup.qml` is the big (~4700-line) settings GUI with tabs General/Weather/Keybinds/Monitors/Startup/Favorites.
- `~/.config/hypr/config/*.conf` (env.conf, settings.conf, autostart.conf, keybinds, monitors) are **auto-regenerated from `~/.config/hypr/templates/*.template` by `~/.config/hypr/scripts/settings_watcher.sh`** — do NOT hand-edit them, edits get clobbered. `hyprland.conf` and `colors.conf` are static and safe to edit.
- Theming is dynamic via **matugen** → `~/.cache/matugen/`. UI scale helper is `root.s(px)`; theme colors are `root.mauve/peach/blue/...`, `root.surface0/1/2`, `root.text`, `root.subtext0`.

**Backup/fork**: config is mirrored to a personal fork **github.com/artur-sorokolit/nixos-configuration** (forked from ilyamiro/nixos-configuration), cloned at `~/nixos-configuration`. The live `~/.config/hypr/` maps to the repo's `config/sessions/hyprland/`. SSH push works as GitHub user `artur-sorokolit` (key `~/.ssh/id_ed25519`); `gh` is NOT installed. The OpenWeather API key in `scripts/quickshell/calendar/.env` is gitignored — never commit it.

**Cursor feature** (added 2026-06): `~/.config/hypr/scripts/quickshell/cursor/` holds `cursor_manager.sh` (list/apply/import) and `render_cursor.py` (Xcursor→PNG preview via Pillow). A "Cursor" card at the bottom of the General settings tab shows a preview gallery + size stepper + Import button. `Config.applyCursor()` applies it. Persistence: gsettings + `~/.icons/default/index.theme` + a dedicated `~/.config/hypr/config/cursor.conf` (sourced from hyprland.conf, kept out of the templated env.conf). Backups: `Config.qml.bak-cursor`, `settings/SettingsPopup.qml.bak-cursor`.

**Music library tab** (added 2026-07-08): the music popup (`scripts/quickshell/music/MusicPopup.qml`) previously only showed an Equalizer. Added a sliding-pill "Equalizer / Library" tab switcher (same visual pattern as the Settings popup's tab bar — animated pill + asymmetric stretch easing) plus a fixed-height content shell (`musicContentArea`, `root.s(267)`) so switching tabs cross-fades instead of resizing the popup. Library tab lists local mp3s from `~/Videos` and plays them via `mpv` (now with the `mpv-mpris` AUR/CachyOS package installed so mpv exposes MPRIS — this is what lets the existing playerctl-based widget/popup see and control local playback at all). Backend: `scripts/quickshell/music/library.sh` (`list` / `play <file>`, tracks the mpv PID in `$QS_RUN_MUSIC/local_player.pid` so only one local track plays at a time). Bound to `SUPER+M` (`qs_manager.sh toggle music`) via `settings.json` keybinds. Backup: `MusicPopup.qml.bak-library`.

**Personal `install.sh`** (added 2026-07-08): root of the fork now has a from-scratch installer (not upstream's) that installs only the packages this config actually calls (derived by grepping `scripts/` for real binary invocations), backs up any existing `~/.config/hypr`, and deploys `config/sessions/hyprland/` in its place. One-liner in the fork's README. Untested end-to-end on a clean machine as of writing.
