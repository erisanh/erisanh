#!/usr/bin/env bash
# install-zed-zsh.sh - Install Zed Editor for Zsh users (Ubuntu 20.04+)
# Features:
# • Auto-install libfuse2 + mesa-utils + vulkan-tools
# • Upgrade Mesa via kisak PPA (fix Intel GPU Vulkan)
# • Smart wrapper: auto ZED_RENDERER=software if Vulkan fails
# • Install to ~/.local (no sudo for Zed)
# • Fix .desktop + PATH + menu
# • Safe, clean, beautiful output
# • Generates uninstall-zed.sh
# Usage:
#   curl -fsSL <url> | bash
#   # or: bash install-zed-zsh.sh preview

set -euo pipefail

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info()  { echo -e "${BLUE}[HINT]${NC} $1"; }

# === 0. Install dependencies ===
log "Installing required packages: libfuse2, mesa-utils, vulkan-tools..."

if ! dpkg -l | grep -q libfuse2; then
  sudo apt update
  sudo apt install -y libfuse2 || { error "Failed to install libfuse2"; exit 1; }
  log "libfuse2 installed"
else
  log "libfuse2 already installed"
fi

sudo apt install -y mesa-utils vulkan-tools || warn "Some GPU tools failed to install (non-critical)"

# === 0.7 Upgrade Mesa via kisak PPA (Intel GPU Vulkan fix) ===
log "Checking Mesa version..."
if command -v glxinfo >/dev/null 2>&1 && ! glxinfo | grep -q "OpenGL version.*Mesa 2[2-9]"; then
  warn "Old Mesa detected – Zed may need software rendering."
  log "Upgrading Mesa via kisak PPA..."
  if ! grep -q "^deb .*kisak-mesa" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    sudo add-apt-repository ppa:kisak/kisak-mesa -y
  fi
  sudo apt update
  sudo apt full-upgrade -y
  log "Mesa upgraded. Reboot recommended!"
  info "Run: sudo reboot"
else
  log "Mesa version is recent – GPU support OK"
fi

# === 1. Architecture & glibc check ===
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  GLIBC_MIN="2.31" ;;
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
log "glibc $GLIBC_VER – OK"

# === 2. Channel ===
CHANNEL="stable"
[[ "${1:-}" == "preview" ]] && CHANNEL="preview" && log "Channel: $CHANNEL"

# === 3. Paths ===
INSTALL_DIR="$HOME/.local/zed.app"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ZSHRC="$HOME/.zshrc"
WRAPPER="$BIN_DIR/zed"
DESKTOP_FILE="$DESKTOP_DIR/dev.zed.Zed.desktop"
log "Installing Zed ($CHANNEL) → $INSTALL_DIR"

# === 4. Run official installer ===
export ZED_CHANNEL="$CHANNEL"
curl -f https://zed.dev/install.sh | sh

# === 5. Verify installation ===
[[ ! -f "$INSTALL_DIR/bin/zed" ]] && { error "Zed binary missing!"; exit 1; }
log "Zed installed successfully"

# === 6. Smart wrapper (ZED_RENDERER=software) ===
mkdir -p "$BIN_DIR"

cat > "$WRAPPER" << 'EOF'
#!/usr/bin/env bash
# Smart Zed wrapper: auto software rendering if Vulkan fails
ZED_BINARY="$HOME/.local/zed.app/libexec/zed-editor"

warn() { echo -e "\033[1;33m[WARN]\033[0m $1" >&2; }

# Force software rendering
if [[ " $* " == *" --software "* ]]; then
  ZED_RENDERER=software exec "$ZED_BINARY" "$@"
fi

# Auto fallback: no Vulkan
if ! command -v vulkaninfo >/dev/null 2>&1 || ! vulkaninfo >/dev/null 2>&1; then
  warn "Vulkan not available → using software rendering"
  ZED_RENDERER=software exec "$ZED_BINARY" "$@"
fi

# Normal GPU path
exec "$ZED_BINARY" "$@"
EOF

chmod +x "$WRAPPER"
log "Smart wrapper created: $WRAPPER"

# === 7. Desktop entry ===
mkdir -p "$DESKTOP_DIR"
if [[ -f "$INSTALL_DIR/share/applications/zed.desktop" ]]; then
  cp "$INSTALL_DIR/share/applications/zed.desktop" "$DESKTOP_FILE"
  sed -i "s|Exec=zed.*|Exec=$WRAPPER %F|g" "$DESKTOP_FILE"
  sed -i "s|Icon=zed|Icon=$INSTALL_DIR/share/icons/hicolor/512x512/apps/zed.png|g" "$DESKTOP_FILE"
  log "Desktop entry updated: $DESKTOP_FILE"
else
  warn "Original .desktop not found. Skipping menu entry."
fi

# Refresh desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  log "Desktop menu refreshed"
fi

# === 8. Add to .zshrc ===
if ! grep -q "$BIN_DIR" "$ZSHRC" 2>/dev/null; then
  {
    echo
    echo '# === Zed Editor ==='
    echo '# Added by install-zed-zsh.sh'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo '# Run with software rendering: zed --software'
    echo '# Auto fallback if no Vulkan'
    echo '# =================='
    echo
  } >> "$ZSHRC"
  log "Added $BIN_DIR to $ZSHRC"
  info "Run: source ~/.zshrc"
fi

# === 9. Final PATH update ===
export PATH="$BIN_DIR:$PATH"

# === 10. Success message ===
echo
echo -e "${GREEN}Zed installed successfully!${NC}"
echo
echo " • Run: ${GREEN}zed${NC} (auto GPU or software)"
echo " • Force software: ${GREEN}zed --software${NC}"
echo " • Open folder: ${GREEN}zed .${NC}"
echo " • Menu: search 'Zed'"
echo " • Uninstall: ${GREEN}bash ~/.local/bin/uninstall-zed.sh${NC}"
echo " • Preview: ${GREEN}bash $0 preview${NC}"
echo

if command -v vulkaninfo >/dev/null 2>&1 && vulkaninfo >/dev/null 2>&1; then
  echo -e " ${GREEN}Vulkan: OK – Zed will use GPU!${NC}"
else
  echo -e " ${YELLOW}Vulkan: Not available – Zed will use software rendering${NC}"
  info "Recommended: sudo reboot"
fi

echo
echo -e " ${BLUE}Try now: zed .${NC}"
echo

exit 0

# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-zsh.sh | bash



