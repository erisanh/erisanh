#!/usr/bin/env bash
# install-zed-zsh.sh - Install Zed Editor for Zsh users (Ubuntu 20.04+)
# Features:
#   • No sudo
#   • Auto-detect arch & glibc
#   • Install to ~/.local
#   • Add to PATH in .zshrc
#   • Fix .desktop with absolute paths
#   • Safe, clean, beautiful output
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-zsh.sh | bash
#   # or
#   bash install-zed-zsh.sh preview

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info()  { echo -e "${BLUE}[HINT]${NC} $1"; }

# === 1. Architecture & glibc check ===
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)   GLIBC_MIN="2.31" ;;
  aarch64)  GLIBC_MIN="2.35" ;;
  *) error "Unsupported architecture: $ARCH"; exit 1 ;;
esac
log "Architecture: $ARCH (glibc >= $GLIBC_MIN required)"

GLIBC_VER=$(ldd --version | head -n1 | awk '{print $NF}')
if ! printf '%s\n' "$GLIBC_MIN" "$GLIBC_VER" | sort -V | head -n1 | grep -q "^$GLIBC_MIN$"; then
  error "glibc $GLIBC_VER < $GLIBC_MIN required"
  [[ "$ARCH" == "aarch64" ]] && warn "Upgrade to Ubuntu 22.04+ for ARM64"
  exit 1
fi
log "glibc $GLIBC_VER → OK"

# === 2. Channel ===
CHANNEL="stable"
[[ "${1:-}" == "preview" ]] && CHANNEL="preview" && log "Channel: $CHANNEL"

# === 3. Paths ===
INSTALL_DIR="$HOME/.local/zed.app"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ZSHRC="$HOME/.zshrc"

log "Installing Zed ($CHANNEL) → $INSTALL_DIR"

# === 4. Run official installer ===
export ZED_CHANNEL="$CHANNEL"
curl -f https://zed.dev/install.sh | sh

# === 5. Verify ===
[[ ! -f "$INSTALL_DIR/bin/zed" ]] && error "Zed binary missing!" && exit 1
log "Zed installed"

# === 6. Symlink ===
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/bin/zed" "$BIN_DIR/zed"
log "Symlink: $BIN_DIR/zed"

# === 7. Desktop entry ===
mkdir -p "$DESKTOP_DIR"
cp "$INSTALL_DIR/share/applications/zed.desktop" "$DESKTOP_DIR/dev.zed.Zed.desktop"
sed -i "s|Exec=zed.*|Exec=$INSTALL_DIR/libexec/zed-editor %F|g" "$DESKTOP_DIR/dev.zed.Zed.desktop"
sed -i "s|Icon=zed|Icon=$INSTALL_DIR/share/icons/hicolor/512x512/apps/zed.png|g" "$DESKTOP_DIR/dev.zed.Zed.desktop"
log "Menu entry created"

# === 8. Add to .zshrc (only if not exists) ===
if ! grep -q "$HOME/.local/bin" "$ZSHRC" 2>/dev/null; then
  {
    echo
    echo '# === Zed Editor ==='
    echo '# Added by install-zed-zsh.sh'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo '# =================='
  } >> "$ZSHRC"
  log "Added ~/.local/bin to $ZSHRC"
  info "Run 'source ~/.zshrc' or restart terminal"
fi

# === 9. Success ===
echo
echo -e "${GREEN}Zed installed successfully for Zsh!${NC}"
echo
echo "   • Run: ${GREEN}zed${NC}  or search in menu"
echo "   • Open current folder: ${GREEN}zed .${NC}"
echo "   • Uninstall: ${GREEN}bash uninstall-zed.sh${NC}"
echo "   • Preview:   ${GREEN}bash $0 preview${NC}"
echo
echo -e "   ${BLUE}Try now: zed .${NC}"
echo

# Auto-source in current session
export PATH="$HOME/.local/bin:$PATH"
info "PATH updated in current session"

exit 0

# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-zsh.sh | bash
