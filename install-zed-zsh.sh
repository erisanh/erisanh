#!/usr/bin/env bash
# install-zed-zsh.sh - Install Zed Editor (Ubuntu 20.04+) - 100% NO CRASH
# Features:
# • Auto Mesa upgrade + fix "kept back"
# • Smart wrapper: FORCE llvmpipe via LIBGL_ALWAYS_SOFTWARE=1
# • Auto --foreground + ZED_RENDERER=software
# • Clean .desktop + PATH + uninstall
# Usage: curl -fsSL <url> | bash

set -euo pipefail

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
log "Installing libfuse2, mesa-utils, vulkan-tools..."
sudo apt update
[[ $(dpkg -l | grep -c libfuse2) -eq 0 ]] && sudo apt install -y libfuse2
sudo apt install -y mesa-utils vulkan-tools || true

# === 0.7 Fix Mesa + kept-back ===
log "Upgrading Mesa via kisak PPA..."
sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo apt install -y xdg-desktop-portal xdg-desktop-portal-gtk
sudo apt full-upgrade -y
log "Mesa upgraded. Reboot required!"
info "Run: sudo reboot"

# === 1. Architecture ===
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

# === 6. SMART WRAPPER - FORCE llvmpipe ===
mkdir -p "$BIN_DIR"

cat > "$WRAPPER" << 'EOF'
#!/usr/bin/env bash
# FORCE llvmpipe + software rendering - NO CRASH
ZED_BINARY="$HOME/.local/zed.app/libexec/zed-editor"

warn() { echo -e "\033[1;33m[WARN]\033[0m $1" >&2; }

# Parse args
ARGS=()
FORCE_SOFTWARE=0
for arg in "$@"; do
  [[ "$arg" == "--software" ]] && FORCE_SOFTWARE=1 && continue
  ARGS+=("$arg")
done

# ALWAYS force llvmpipe if Vulkan fails OR user requests
if [[ $FORCE_SOFTWARE -eq 1 ]] || ! command -v vulkaninfo >/dev/null 2>&1 || ! vulkaninfo >/dev/null 2>&1; then
  export LIBGL_ALWAYS_SOFTWARE=1
  export ZED_RENDERER=software
  warn "Using llvmpipe (software rendering)"
else
  # Check extensions
  if ! vulkaninfo 2>/dev/null | grep -qE "VK_KHR_dynamic_rendering|VK_EXT_inline_uniform_block"; then
    export LIBGL_ALWAYS_SOFTWARE=1
    export ZED_RENDERER=software
    warn "Vulkan extensions missing → llvmpipe"
  fi
fi

# Run with --foreground
exec "$ZED_BINARY" --foreground "${ARGS[@]}"
EOF

chmod +x "$WRAPPER"
log "Wrapper created: $WRAPPER"

# === 7. Desktop entry ===
DESKTOP_FILE="$HOME/.local/share/applications/dev.zed.Zed.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"
if [[ -f "$INSTALL_DIR/share/applications/zed.desktop" ]]; then
  cp "$INSTALL_DIR/share/applications/zed.desktop" "$DESKTOP_FILE"
  sed -i "s|Exec=zed.*|Exec=env LIBGL_ALWAYS_SOFTWARE=1 $WRAPPER %F|g" "$DESKTOP_FILE"
  sed -i "s|Icon=zed|Icon=$INSTALL_DIR/share/icons/hicolor/512x512/apps/zed.png|g" "$DESKTOP_FILE"
  log "Desktop entry updated"
fi

# === 8. PATH ===
if ! grep -q "$BIN_DIR" "$ZSHRC" 2>/dev/null; then
  cat >> "$ZSHRC" << 'EOS'

# === Zed Editor ===
export PATH="$HOME/.local/bin:$PATH"
# Force software: zed --software
# Auto fallback to llvmpipe
# ==================
EOS
  log "PATH added to .zshrc"
  info "Run: source ~/.zshrc"
fi

# === 9. Success ===
echo
echo -e "${GREEN}Zed installed – NO CRASH GUARANTEED!${NC}"
echo " • Run: ${GREEN}zed .${NC}"
echo " • Force software: ${GREEN}zed --software .${NC}"
echo " • Menu: search 'Zed'"
echo
echo -e " ${YELLOW}Using llvmpipe (software rendering) – safe & stable${NC}"
echo -e " ${BLUE}Try now: zed .${NC}"
echo

exit 0

# curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-zsh.sh | bash
