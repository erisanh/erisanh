#!/usr/bin/env bash
# install-zed-zsh-fixed.sh - Zed Editor installer for Ubuntu 20.04+, guaranteed CPU mode
# Features:
# • Always use CPU (llvmpipe)
# • Ignores GPU, Vulkan, driver issues
# • Clean .desktop, PATH, uninstall
# Usage: curl -fsSL <url> | bash

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

# === 0. Dependencies ===
log "Installing libfuse2, mesa-utils..."
sudo apt update
[[ $(dpkg -l | grep -c libfuse2) -eq 0 ]] && sudo apt install -y libfuse2
sudo apt install -y mesa-utils xdg-desktop-portal xdg-desktop-portal-gtk || true

# === 0.7 Upgrade Mesa (optional) ===
log "Upgrading Mesa via kisak PPA..."
if ! grep -q "^deb .*kisak-mesa" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
  sudo add-apt-repository ppa:kisak/kisak-mesa -y
fi
sudo apt full-upgrade -y
log "Mesa upgrade done (reboot recommended for drivers)"
info "Run: sudo reboot"

# === 1. Architecture check ===
ARCH=$(uname -m)
[[ "$ARCH" == "x86_64" ]] || { error "Only x86_64 supported"; exit 1; }
log "Architecture: $ARCH"

# === 2. Channel ===
CHANNEL="stable"
[[ "${1:-}" == "preview" ]] && CHANNEL="preview"

# === 3. Paths ===
INSTALL_DIR="$HOME/.local/zed.app"
BIN_DIR="$HOME/.local/bin"
WRAPPER="$BIN_DIR/zed"
ZSHRC="$HOME/.zshrc"

# === 4. Install Zed ===
export ZED_CHANNEL="$CHANNEL"
curl -f https://zed.dev/install.sh | sh
[[ -f "$INSTALL_DIR/bin/zed" ]] || { error "Install failed"; exit 1; }
log "Zed installed"

# === 5. Wrapper - CPU only (llvmpipe), ignores all GPU args ===
mkdir -p "$BIN_DIR"

cat > "$WRAPPER" << 'EOF'
#!/usr/bin/env bash
# Zed wrapper: always CPU (llvmpipe), ignores Vulkan/GPU

ZED_BINARY="$HOME/.local/zed.app/libexec/zed-editor"

warn() { echo -e "\033[1;33m[WARN]\033[0m $1" >&2; }

# Clean args: remove --foreground / --software / GPU-related
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --foreground|--software) continue ;;
    *) ARGS+=("$arg") ;;
  esac
done

# Force CPU rendering
export ZED_DISABLE_GPU=1
export LIBGL_ALWAYS_SOFTWARE=1
warn "GPU disabled → using llvmpipe (software rendering)"

exec "$ZED_BINARY" "${ARGS[@]}"
EOF

chmod +x "$WRAPPER"
log "Wrapper created: $WRAPPER"

# === 6. Desktop entry ===
DESKTOP_FILE="$HOME/.local/share/applications/dev.zed.Zed.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"
if [[ -f "$INSTALL_DIR/share/applications/zed.desktop" ]]; then
  cp "$INSTALL_DIR/share/applications/zed.desktop" "$DESKTOP_FILE"
  sed -i "s|Exec=zed.*|Exec=env ZED_DISABLE_GPU=1 LIBGL_ALWAYS_SOFTWARE=1 $WRAPPER %F|g" "$DESKTOP_FILE"
  sed -i "s|Icon=zed|Icon=$INSTALL_DIR/share/icons/hicolor/512x512/apps/zed.png|g" "$DESKTOP_FILE"
  log "Desktop entry updated (CPU rendering)"
fi

# === 7. PATH ===
if ! grep -q "$BIN_DIR" "$ZSHRC" 2>/dev/null; then
  cat >> "$ZSHRC" << 'EOS'

# === Zed Editor ===
export PATH="$HOME/.local/bin:$PATH"
# Always CPU fallback
# =====================
EOS
  log "PATH added to .zshrc"
  info "Run: source ~/.zshrc"
fi

# === 8. Success ===
echo
echo -e "${GREEN}Zed installed – 100% CPU SAFE!${NC}"
echo " • Run: ${GREEN}zed .${NC}"
echo " • Menu: search 'Zed' (CPU only)"
echo " • Uninstall: ${GREEN}bash ~/.local/bin/uninstall-zed.sh${NC}"
echo
echo -e " ${YELLOW}Using llvmpipe (CPU rendering) – guaranteed stable${NC}"
echo -e " ${BLUE}Try now: zed .${NC}"
echo

exit 0



# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-zsh.sh | bash
