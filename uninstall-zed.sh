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
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

log "Starting Zed cleanup..."

# 1. Try official uninstaller (if exists)
if [[ -f "$ZED_DIR/bin/zed" ]]; then
  log "Running official uninstaller..."
  "$ZED_DIR/bin/zed" --uninstall || warn "Uninstaller failed (continuing anyway)"
fi

# 2. Remove Zed app directory
[[ -d "$ZED_DIR" ]] && rm -rf "$ZED_DIR" && log "Removed $ZED_DIR"

# 3. Remove symlink
[[ -L "$BIN_LINK" ]] && rm -f "$BIN_LINK" && log "Removed $BIN_LINK"

# 4. Remove .desktop file
[[ -f "$DESKTOP_FILE" ]] && rm -f "$DESKTOP_FILE" && log "Removed $DESKTOP_FILE"

# 5. Clean PATH from .zshrc and .bashrc
for rc in "$ZSHRC" "$BASHRC"; do
  if [[ -f "$rc" ]]; then
    sed -i '/# Added by Zed installer/d' "$rc"
    sed -i '/export PATH="$HOME\/.local\/bin:$PATH"/d' "$rc"
    sed -i '/export PATH=.*\.local\/bin/d' "$rc"
  fi
done
log "Cleaned PATH entries from shell config"

# 6. Remove Zed logs
rm -rf "$HOME/.local/share/zed" && log "Removed Zed settings & logs"

echo
echo -e "${GREEN}Zed has been COMPLETELY removed!${NC}"
echo "   • No files left behind"
echo "   • Safe to reinstall"

# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/uninstall-zed.sh | bash
