#!/usr/bin/env bash
#
# Personal installer for artur-sorokolit/nixos-configuration.
#
# Lean, non-interactive bootstrap for MY exact machine/setup — not a
# general-purpose installer for arbitrary users (see ilyamiro/imperative-dots
# for that). Installs the packages this config actually calls, then deploys
# config/sessions/hyprland/ to ~/.config/hypr.
#
# Supported: Arch/CachyOS (via paru), Ubuntu (via apt + GitHub releases)
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

# ── Detect distro ──────────────────────────────────────────────────────────────
if command -v pacman >/dev/null 2>&1; then
    DISTRO="arch"
elif command -v apt-get >/dev/null 2>&1; then
    DISTRO="ubuntu"
else
    echo "Unsupported distro — only Arch and Ubuntu are supported." >&2
    exit 1
fi
echo "==> Detected: $DISTRO"

# ══════════════════════════════════════════════════════════════════════════════
#  ARCH / CachyOS
# ══════════════════════════════════════════════════════════════════════════════
install_arch() {
    if ! command -v paru >/dev/null 2>&1; then
        echo "==> Bootstrapping paru"
        sudo pacman -S --needed --noconfirm base-devel git
        tmp=$(mktemp -d)
        git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
        (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi

    paru -S --needed --noconfirm \
        hyprland hypridle \
        mpv mpv-mpris \
        kitty playerctl jq imagemagick ffmpeg easyeffects \
        python python-pillow \
        git curl zenity tar unzip inotify-tools \
        wl-clipboard grim slurp brightnessctl libnotify \
        pipewire pipewire-pulse wireplumber \
        quickshell-git matugen-bin swayosd-git
}

# ══════════════════════════════════════════════════════════════════════════════
#  UBUNTU
# ══════════════════════════════════════════════════════════════════════════════

# Download latest GitHub release asset matching a regex pattern
gh_release_download() {
    local repo="$1" pattern="$2" dest="$3"
    local url
    url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -oP '"browser_download_url":\s*"\K[^"]+' \
        | grep -E "$pattern" | head -1)
    if [[ -z "$url" ]]; then
        echo "==> No release asset matching '$pattern' found in $repo" >&2
        return 1
    fi
    echo "==> Downloading $(basename "$url")"
    curl -fsSL "$url" -o "$dest"
}

ensure_cargo() {
    if ! command -v cargo >/dev/null 2>&1; then
        echo "==> Installing Rust"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env"
    fi
}

_install_matugen() {
    echo "==> matugen"
    local tmp; tmp=$(mktemp -d)
    if gh_release_download "InioX/matugen" "x86_64-unknown-linux-musl\.tar\.gz$" "$tmp/matugen.tar.gz"; then
        tar -xzf "$tmp/matugen.tar.gz" -C "$tmp"
        sudo install -Dm755 "$tmp/matugen" /usr/local/bin/matugen
    else
        ensure_cargo
        cargo install matugen
    fi
    rm -rf "$tmp"
}

_install_swayosd() {
    echo "==> swayosd"
    local tmp; tmp=$(mktemp -d)
    if gh_release_download "ErikReider/SwayOSD" "\.deb$" "$tmp/swayosd.deb"; then
        sudo apt-get install -y "$tmp/swayosd.deb"
    else
        sudo apt-get install -y --no-install-recommends \
            libgtk-4-dev libgtk-layer-shell-dev libpulse-dev
        ensure_cargo
        cargo install --git https://github.com/ErikReider/SwayOSD
    fi
    rm -rf "$tmp"
}

_install_quickshell() {
    echo "==> quickshell"
    local tmp; tmp=$(mktemp -d)
    if gh_release_download "outfoxxed/quickshell" "\.AppImage$" "$tmp/quickshell.AppImage"; then
        sudo install -Dm755 "$tmp/quickshell.AppImage" /usr/local/bin/quickshell
        rm -rf "$tmp"
        return
    fi
    rm -rf "$tmp"

    echo "==> Building quickshell from source (takes a few minutes)"
    sudo apt-get install -y --no-install-recommends \
        cmake clang ninja-build pkg-config \
        qt6-base-dev qt6-declarative-dev libqt6svg6-dev \
        qt6-wayland-dev libxkbcommon-dev \
        libpipewire-0.3-dev libpam0g-dev
    local build; build=$(mktemp -d)
    git clone --recursive --depth=1 https://github.com/outfoxxed/quickshell.git "$build/src"
    cmake -B "$build/build" -S "$build/src" -DCMAKE_BUILD_TYPE=Release -G Ninja
    ninja -C "$build/build"
    sudo install -Dm755 "$build/build/quickshell" /usr/local/bin/quickshell
    rm -rf "$build"
}

_install_mpv_mpris() {
    echo "==> mpv-mpris"
    local tmp; tmp=$(mktemp -d)
    local dest="$HOME/.config/mpv/scripts"
    mkdir -p "$dest"
    if gh_release_download "hoyon/mpv-mpris" "mpris\.so$" "$tmp/mpris.so"; then
        cp "$tmp/mpris.so" "$dest/mpris.so"
    else
        sudo apt-get install -y --no-install-recommends libmpv-dev
        git clone --depth=1 https://github.com/hoyon/mpv-mpris.git "$tmp/src"
        make -C "$tmp/src"
        cp "$tmp/src/mpris.so" "$dest/mpris.so"
    fi
    rm -rf "$tmp"
}

install_ubuntu() {
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends \
        hyprland hypridle \
        mpv \
        kitty playerctl jq imagemagick ffmpeg easyeffects \
        python3 python3-pil \
        git curl zenity tar unzip inotify-tools \
        wl-clipboard grim slurp brightnessctl libnotify-bin \
        pipewire pipewire-pulse wireplumber

    _install_matugen
    _install_swayosd
    _install_quickshell
    _install_mpv_mpris
}

# ── Dispatch ───────────────────────────────────────────────────────────────────
case "$DISTRO" in
    arch)   install_arch ;;
    ubuntu) install_ubuntu ;;
esac

# ── 3. Get the repo ────────────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
    echo "==> Updating existing $REPO_DIR"
    git -C "$REPO_DIR" pull --ff-only
else
    echo "==> Cloning $REPO_URL to $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
fi

# ── 4. Back up any existing hypr config, then deploy ──────────────────────────
if [ -d "$HOME/.config/hypr" ]; then
    backup_dir="$HOME/.config/hypr-backup-$(date +%Y%m%d_%H%M%S)"
    echo "==> Backing up ~/.config/hypr to $backup_dir"
    mv "$HOME/.config/hypr" "$backup_dir"
fi

echo "==> Deploying config"
mkdir -p "$HOME/.config/hypr"
rsync -a "$REPO_DIR/config/sessions/hyprland/" "$HOME/.config/hypr/"
find "$HOME/.config/hypr/scripts" -name "*.sh" -exec chmod +x {} \;

# ── 5. Services ────────────────────────────────────────────────────────────────
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

echo ""
echo "==> Done."
echo "    - OpenWeather API key was intentionally NOT synced (gitignored):"
echo "      set it up in ~/.config/hypr/scripts/quickshell/calendar/.env"
echo "    - The sidebar's AI Terminal tab runs 'claude' by default (configurable"
echo "      in Settings > General). The Claude Code CLI is NOT installed by this"
echo "      script — see https://docs.claude.com/claude-code for install steps."
echo "    - Log into a Hyprland session (or run: Hyprland) to start."
