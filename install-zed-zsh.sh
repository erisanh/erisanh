#!/usr/bin/env bash
# install-zed-zsh.sh - Install Zed Editor for Zsh users (Ubuntu 20.04+)
# Features:
# • Auto-install libfuse2 + mesa-utils
# • Upgrade Mesa via kisak PPA (fix Intel GPU Vulkan)
# • Smart zed wrapper: auto --gpu=software if needed
# • Install to ~/.local (no sudo for Zed)
# • Fix .desktop + PATH + menu
# • Safe, clean, beautiful output
# Usage:
# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-zsh.sh | bash
# # or: bash install-zed-zsh.sh preview

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[HINT]${NC} $1"; }

# === 0. Install libfuse2 (required for AppImage) ===
if ! dpkg -l | grep -q libfuse2; then
  log "Installing libfuse2 (required for Zed AppImage)..."
  sudo apt update && sudo apt install -y libfuse2 || {
    error "Failed to install libfuse2"
    exit 1
  }
  log "libfuse2 installed"
else
  log "libfuse2 already installed"
fi

# === 0.5 Install mesa-utils for GPU check ===
if ! command -v glxinfo >/dev/null 2>&1; then
  log "Installing mesa-utils for GPU detection..."
  sudo apt install -y mesa-utils || warn "mesa-utils install failed (non-critical)"
fi

# === 0.7 Upgrade Mesa for Intel GPU (fix Vulkan) ===
log "Checking Mesa version for GPU support..."
if command -v glxinfo >/dev/null 2>&1 && ! glxinfo | grep -q "OpenGL version.*Mesa 22"; then
  warn "Mesa cũ! Zed có thể cần --gpu=software"
  log "Upgrading Mesa via kisak PPA (safe & recommended)..."
  if ! grep -q "^deb .*kisak-mesa" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    sudo add-apt-repository ppa:kisak/kisak-mesa -y
  fi
  sudo apt update
  sudo apt full-upgrade -y
  log "Mesa upgraded. Reboot khuyến khích!"
  info "Run: sudo reboot"
else
  log "Mesa đủ mới → GPU support OK"
fi

# === 1. Architecture & glibc check ===
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) GLIBC_MIN="2.31" ;;
  aarch64) GLIBC_MIN="2.35" ;;
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

# === 6. Smart wrapper (support --gpu=software) ===
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/zed" << 'EOF'
#!/usr/bin/env bash
# Smart Zed wrapper: auto software rendering if Vulkan fails
ZED_BINARY="$HOME/.local/zed.app/libexec/zed-editor"

# Force software if requested
if [[ " $* " == *" --gpu=software "* ]]; then
  exec "$ZED_BINARY" --gpu=software "$@"
fi

# Auto fallback if no Vulkan
if ! command -v vulkaninfo >/dev/null 2>&1 || ! vulkaninfo >/dev/null 2>&1; then
  warn "Vulkan not available → using software rendering"
  exec "$ZED_BINARY" --gpu=software "$@"
fi

# Normal GPU path
exec "$ZED_BINARY" "$@"
EOF
chmod +x "$BIN_DIR/zed"
log "Smart wrapper created: $BIN_DIR/zed"

# === 7. Desktop entry ===
mkdir -p "$DESKTOP_DIR"
cp "$INSTALL_DIR/share/applications/zed.desktop" "$DESKTOP_DIR/dev.zed.Zed.desktop"
sed -i "s|Exec=zed.*|Exec=$BIN_DIR/zed %F|g" "$DESKTOP_DIR/dev.zed.Zed.desktop"
sed -i "s|Icon=zed|Icon=$INSTALL_DIR/share/icons/hicolor/512x512/apps/zed.png|g" "$DESKTOP_DIR/dev.zed.Zed.desktop"
log "Menu entry: $DESKTOP_DIR/dev.zed.Zed.desktop"

# Refresh desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  log "Desktop menu updated"
fi

# === 8. Add to .zshrc ===
if ! grep -q "$HOME/.local/bin" "$ZSHRC" 2>/dev/null; then
  {
    echo
    echo '# === Zed Editor ==='
    echo '# Added by install-zed-zsh.sh'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo '# Run with software rendering: zed --gpu=software'
    echo '# =================='
    echo
  } >> "$ZSHRC"
  log "Added ~/.local/bin to $ZSHRC"
  info "Run: source ~/.zshrc"
fi

# === 9. Final PATH update ===
export PATH="$HOME/.local/bin:$PATH"

# === 10. Success ===
echo
echo -e "${GREEN}Zed installed successfully!${NC}"
echo
echo " • Run: ${GREEN}zed${NC} (auto GPU hoặc software)"
echo " • Force software: ${GREEN}zed --gpu=software${NC}"
echo " • Open folder: ${GREEN}zed .${NC}"
echo " • Menu: search 'Zed'"
echo " • Uninstall: ${GREEN}rm -rf ~/.local/zed.app ~/.local/bin/zed && sed -i '/Zed Editor/d' ~/.zshrc${NC}"
echo " • Preview: ${GREEN}bash $0 preview${NC}"
echo
if glxinfo 2>/dev/null | grep -q "Mesa 2[2-9]"; then
  echo -e " ${GREEN}GPU: Mesa mới → Zed sẽ chạy mượt!${NC}"
else
  echo -e " ${YELLOW}GPU: Mesa cũ → Zed dùng software rendering${NC}"
  info "Khuyến khích: sudo reboot"
fi
echo
echo -e " ${BLUE}Try now: zed .${NC}"
echo

exit 0

# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-zsh.sh | bash
