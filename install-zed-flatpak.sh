#!/bin/bash
# install-zed.sh - Cài Zed Editor trên Ubuntu 20.04 (x86_64 / aarch64)
# Tác giả: ChatGPT (dựa trên tài liệu chính thức zed.dev)
# Chạy: bash install-zed.sh          # stable
#       bash install-zed.sh preview  # preview channel

set -e  # Dừng nếu có lỗi

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Kiểm tra kiến trúc
ARCH=$(uname -m)
case $ARCH in
  x86_64)   GLIBC_MIN="2.31" ;;
  aarch64)  GLIBC_MIN="2.35" ;;
  *) error "Kiến trúc không được hỗ trợ: $ARCH"; exit 1 ;;
esac

log "Kiến trúc: $ARCH (yêu cầu glibc >= $GLIBC_MIN)"

# Kiểm tra glibc
GLIBC_VER=$(ldd --version | head -n1 | awk '{print $NF}')
if [ -z "$(printf '%s\n' "$GLIBC_MIN" "$GLIBC_VER" | sort -V | head -n1)" ]; then
  error "glibc $GLIBC_VER < $GLIBC_MIN → Không hỗ trợ. Cần Ubuntu 22.04+ cho ARM."
  exit 1
fi
log "glibc $GLIBC_VER → OK"

# Xác định channel
CHANNEL="stable"
if [ "$1" = "preview" ]; then
  CHANNEL="preview"
  log "Cài đặt kênh: $CHANNEL"
fi

# Thư mục cài đặt
INSTALL_DIR="$HOME/.local/zed.app"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"

log "Tải và cài Zed ($CHANNEL) vào $INSTALL_DIR..."

# Tải script cài đặt và chạy
export ZED_CHANNEL="$CHANNEL"
curl -f https://zed.dev/install.sh | sh

# Kiểm tra cài đặt thành công
if [ ! -f "$INSTALL_DIR/bin/zed" ]; then
  error "Cài đặt thất bại: Không tìm thấy $INSTALL_DIR/bin/zed"
  exit 1
fi

# Tạo symlink
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/bin/zed" "$BIN_DIR/zed"
log "Tạo symlink: $BIN_DIR/zed → zed.app"

# Cài .desktop file (tích hợp menu)
mkdir -p "$DESKTOP_DIR" "$ICON_DIR"
cp "$INSTALL_DIR/share/applications/zed.desktop" "$DESKTOP_DIR/dev.zed.Zed.desktop"

# Sửa đường dẫn Exec và Icon
sed -i "s|Exec=zed|Exec=$INSTALL_DIR/libexec/zed-editor %F|g" "$DESKTOP_DIR/dev.zed.Zed.desktop"
sed -i "s|Icon=zed|Icon=$INSTALL_DIR/share/icons/hicolor/512x512/apps/zed.png|g" "$DESKTOP_DIR/dev.zed.Zed.desktop"

log "Cài .desktop → có thể tìm Zed trong menu"

# Hoàn tất
echo
echo -e "${GREEN}Zed đã được cài đặt thành công!${NC}"
echo
echo "   • Chạy: ${GREEN}zed${NC} hoặc tìm trong menu"
echo "   • Gỡ cài đặt: ${GREEN}zed --uninstall${NC}"
echo "   • Preview: ${GREEN}bash install-zed.sh preview${NC}"
echo
echo "Mở thử ngay: ${GREEN}zed .${NC}"


# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-flatpak.sh)"
