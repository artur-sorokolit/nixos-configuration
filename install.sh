#!/usr/bin/env bash
#
# Personal installer for artur-sorokolit/nixos-configuration.
#
# Lean, non-interactive bootstrap for MY exact machine/setup — not a
# general-purpose installer for arbitrary users (see ilyamiro/imperative-dots
# for that). Installs the packages this config actually calls, then deploys
# config/sessions/hyprland/ to ~/.config/hypr.
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/artur-sorokolit/nixos-configuration/master/install.sh)"

set -euo pipefail

REPO_URL="https://github.com/artur-sorokolit/nixos-configuration.git"
REPO_DIR="$HOME/nixos-configuration"

if [ "$EUID" -eq 0 ]; then
    echo "Do not run this as root." >&2
    exit 1
fi

# --- 1. AUR helper (paru) ---------------------------------------------------
if ! command -v paru >/dev/null 2>&1; then
    echo "==> paru not found, bootstrapping it"
    sudo pacman -S --needed --noconfirm base-devel git
    tmp_paru=$(mktemp -d)
    git clone https://aur.archlinux.org/paru-bin.git "$tmp_paru/paru-bin"
    (cd "$tmp_paru/paru-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp_paru"
fi

# --- 2. Packages -------------------------------------------------------------
# Official repos (incl. CachyOS's prebuilt extras — paru resolves either way)
PKGS=(
    hyprland hypridle
    mpv mpv-mpris
    kitty
    playerctl
    jq
    imagemagick
    ffmpeg
    easyeffects
    python python-pillow
    git curl
    zenity
    tar unzip
    inotify-tools
    wl-clipboard
    grim slurp
    brightnessctl
    libnotify
    pipewire pipewire-pulse wireplumber
    quickshell-git
    matugen-bin
    swayosd-git
)

echo "==> Installing packages: ${PKGS[*]}"
paru -S --needed --noconfirm "${PKGS[@]}"

# --- 3. Get the repo ----------------------------------------------------------
if [ -d "$REPO_DIR/.git" ]; then
    echo "==> Updating existing $REPO_DIR"
    git -C "$REPO_DIR" pull --ff-only
else
    echo "==> Cloning $REPO_URL to $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
fi

# --- 4. Back up any existing hypr config, then deploy -------------------------
if [ -d "$HOME/.config/hypr" ]; then
    backup_dir="$HOME/.config/hypr-backup-$(date +%Y%m%d_%H%M%S)"
    echo "==> Backing up existing ~/.config/hypr to $backup_dir"
    mv "$HOME/.config/hypr" "$backup_dir"
fi

echo "==> Deploying config"
mkdir -p "$HOME/.config/hypr"
rsync -a "$REPO_DIR/config/sessions/hyprland/" "$HOME/.config/hypr/"

find "$HOME/.config/hypr/scripts" -name "*.sh" -exec chmod +x {} \;

# --- 5. Services --------------------------------------------------------------
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

echo ""
echo "==> Done."
echo "    - OpenWeather API key was intentionally NOT synced (gitignored):"
echo "      set it up in ~/.config/hypr/scripts/quickshell/calendar/.env"
echo "    - The sidebar's AI Terminal tab runs 'claude' by default (configurable"
echo "      in Settings > General). The Claude Code CLI is NOT installed by this"
echo "      script — see https://docs.claude.com/claude-code for install steps."
echo "    - Log into a Hyprland session (or run: Hyprland) to start."
