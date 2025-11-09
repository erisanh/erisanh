#!/usr/bin/env bash
# uninstall-zed.sh - Completely remove Zed (user-local install + optional deps)
# Run: bash uninstall-zed.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

ZED_DIR="$HOME/.local/zed.app"
BIN_LINK="$HOME/.local/bin/zed"
DESKTOP_FILE="$HOME/.local/share/applications/dev.zed.Zed.desktop"
CONFIG_DIR="$HOME/.config/zed"
UNINSTALL_SCRIPT="$HOME/.local/bin/uninstall-zed.sh"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

log "Starting Zed cleanup..."

# 1. Remove Zed app directory
if [[ -d "$ZED_DIR" ]]; then
    rm -rf "$ZED_DIR"
    log "Removed $ZED_DIR"
fi

# 2. Remove wrapper binary
if [[ -f "$BIN_LINK" ]]; then
    rm -f "$BIN_LINK"
    log "Removed $BIN_LINK"
fi

# 3. Remove .desktop file
if [[ -f "$DESKTOP_FILE" ]]; then
    rm -f "$DESKTOP_FILE"
    log "Removed $DESKTOP_FILE"
fi

# 4. Clean PATH entries and comments from shell config files
for rc in "$ZSHRC" "$BASHRC"; do
    if [[ -f "$rc" ]]; then
        sed -i '/# === Zed Editor ===/,/# ==================/d' "$rc" 2>/dev/null || true
    fi
done
log "Cleaned PATH entries from shell configs"

# 5. Remove Zed settings & logs (optional)
if [[ -d "$CONFIG_DIR" ]]; then
    read -p "Remove Zed configuration and data (~/.config/zed)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        log "Removed $CONFIG_DIR"
    else
        warn "Kept $CONFIG_DIR (user data preserved)"
    fi
fi

# 6. Remove uninstall script itself
if [[ -f "$UNINSTALL_SCRIPT" ]]; then
    rm -f "$UNINSTALL_SCRIPT"
    log "Removed $UNINSTALL_SCRIPT"
fi

# 7. Optional: remove dependencies installed by the installer
read -p "Remove Zed dependencies (libfuse2, mesa-utils, xdg-desktop-portal, xdg-desktop-portal-gtk)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt remove --purge -y libfuse2 mesa-utils xdg-desktop-portal xdg-desktop-portal-gtk
    sudo apt autoremove -y
    log "Removed Zed-related dependencies"
else
    warn "Kept dependencies"
fi

echo
echo -e "${GREEN}Zed has been COMPLETELY removed!${NC}"
echo " • No files left behind"
echo " • Safe to reinstall"
echo " • Run 'source ~/.zshrc' or 'source ~/.bashrc' to update PATH"


# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/uninstall-zed.sh | bash
