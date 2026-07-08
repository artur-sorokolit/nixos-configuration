# 🍴 Personal fork — Arch / CachyOS

This is my personal fork of [**ilyamiro/nixos-configuration**](https://github.com/ilyamiro/nixos-configuration),
adapted to run on **CachyOS (Arch-based)** rather than NixOS. It's primarily a backup of my live
`~/.config/hypr/` (mirrored into `config/sessions/hyprland/`), plus a backup of my
[Claude Code](https://claude.com/claude-code) skills/memory in `claude/` (see `claude/README.md`).

**My additions on top of upstream:**
- **Cursor settings** — a cursor manager built into the Quickshell settings (General tab): theme
  preview gallery, size stepper, and an "Import downloaded cursor" button.
  Lives in `scripts/quickshell/cursor/` (`render_cursor.py`, `cursor_manager.sh`).
- **Wallpaper fixes** — tweaks to `wallpaper/WallpaperPicker.qml` and `wallpaper/matugen_reload.sh`.
- **Music library tab** — local mp3 playback (via mpv + mpv-mpris) added to the music popup
  alongside the equalizer, with a sliding-tab switcher. Lives in `scripts/quickshell/music/library.sh`.
- **Favorite applications** — my own favourites configured in `settings.json`.
- Misc local scripts: `settings_watcher.sh`, `init.sh`, `layout_switcher.sh`,
  `focus_next_monitor.sh`, `update_notifier.sh`, and `BatteryPopupAlt.qml`.

> [!NOTE]
> The OpenWeather API key (`scripts/quickshell/calendar/.env`) is intentionally **not** committed (gitignored).

## Installing this exact setup

This is **my own installer**, not upstream's — it installs only the packages my config actually
uses (no menus, no telemetry, no driver selection) and deploys `config/sessions/hyprland/` to
`~/.config/hypr`, backing up any existing config first:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/artur-sorokolit/nixos-configuration/master/install.sh)"
```

For upstream's full interactive installer (menus, GPU driver setup, optional packages), see
[ilyamiro/imperative-dots](https://github.com/ilyamiro/imperative-dots) — but note that installs
*his* base config, not mine; you'd still need to run the command above afterward to overlay this fork.

All credit for the original configuration goes to [@ilyamiro](https://github.com/ilyamiro).

---

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/ilyamiro)

# Big announcement to all of my users! 
### Starting from 12.05.2026, the version of my dots will remain available for arch on version v1.7.6, since I am working on a very big update - v2.0.0. It will shift the whole paradigm - instead of being invasive into your configs, the shell will actually be a "shell" and be just a quickshell configuration on top of your compositor - that will extend the support onto Niri, MangoWM, and other wayland compositors other than Hyprland. The new update will also make everything much more optimized and efficient and will be out in a span of a month. Thank you!


## Do NOT install it on NixOS. This config has a lot adapting to do, until I introduce flakes.
## Arch installer now available for everyone. Just run this: 

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh)"
```

> [!WARNING]
> DO NOT LAUNCH THIS AS ROOT!

> [!NOTE]
> This installer sends anonymous non-identifying telemetry that helps me debug problems and track the amount of users

### You can find all of my wallpapers **[HERE](https://github.com/ilyamiro/shell-wallpapers)**.

## Previews of my desktop

---

![preview1](previews/screenshot1.png)
![preview2](previews/screenshot2.png)
![preview3](previews/screenshot3.png)
![preview4](previews/screenshot4.png)
![preview5](previews/screenshot5.png)
![preview6](previews/screenshot6.png)
![preview7](previews/screenshot7.png)
![preview8](previews/screenshot8.png)
![preview9](previews/screenshot9.png)
![preview10](previews/screenshot10.png)

