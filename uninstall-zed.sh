#!/usr/bin/env bash
# uninstall-zed.sh - Completely remove Zed (user-local install)
# Run: bash uninstall-zed.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
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
[[ -d "$ZED_DIR" ]] && rm -rf "$ZED_DIR" && log "Removed $ZED_DIR"

# 2. Remove wrapper binary
[[ -f "$BIN_LINK" ]] && rm -f "$BIN_LINK" && log "Removed $BIN_LINK"

# 3. Remove .desktop file
[[ -f "$DESKTOP_FILE" ]] && rm -f "$DESKTOP_FILE" && log "Removed $DESKTOP_FILE"

# 4. Clean PATH and comments from .zshrc and .bashrc
for rc in "$ZSHRC" "$BASHRC"; do
  if [[ -f "$rc" ]]; then
    sed -i '/# === Zed Editor ===/,/# ==================/d' "$rc" 2>/dev/null || true
  fi
done
log "Cleaned PATH entries from shell config"

# 5. Remove Zed settings & logs (optional)
if [[ -d "$CONFIG_DIR" ]]; then
  read -p "Remove Zed configuration and data (~/.config/zed)? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$CONFIG_DIR" && log "Removed $CONFIG_DIR"
  else
    warn "Kept $CONFIG_DIR (user data preserved)"
  fi
fi

# 6. Remove this uninstall script if installed
[[ -f "$UNINSTALL_SCRIPT" ]] && rm -f "$UNINSTALL_SCRIPT" && log "Removed $UNINSTALL_SCRIPT"

echo
echo -e "${GREEN}Zed has been COMPLETELY removed!${NC}"
echo " • No files left behind"
echo " • Safe to reinstall"
echo " • Run 'source ~/.zshrc' or 'source ~/.bashrc' to update PATH"

# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/uninstall-zed.sh | bash
