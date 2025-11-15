#!/usr/bin/env bash
# zed-disable-gpu.sh - Disable GPU for Zed on Ubuntu 20.04.6
# Usage: bash zed-disable-gpu.sh

set -e

WRAPPER="/usr/local/bin/zed-no-gpu"
DESKTOP="/usr/share/applications/zed.desktop"
BACKUP="$DESKTOP.bak"

echo "=== Disabling GPU for Zed ==="

# Detect Zed binary
if [ -x "/opt/zed/zed" ]; then
    ZED_BIN="/opt/zed/zed"
elif command -v zed &>/dev/null; then
    ZED_BIN="$(command -v zed)"
else
    echo "❌ Zed Editor not found. Please check your installation."
    exit 1
fi
echo "✔ Found Zed at: $ZED_BIN"

# Create wrapper
echo "Creating wrapper script at $WRAPPER..."
sudo bash -c "cat > '$WRAPPER'" <<EOF
#!/usr/bin/env bash
export ZED_DISABLE_GPU=1
export LIBGL_ALWAYS_SOFTWARE=1
exec "$ZED_BIN" "\$@"
EOF
sudo chmod +x "$WRAPPER"
echo "✔ Wrapper created."

# Patch .desktop
if [ -f "$DESKTOP" ]; then
    echo "Patching $DESKTOP..."
    sudo cp "$DESKTOP" "$BACKUP"
    sudo sed -i "s|Exec=.*|Exec=$WRAPPER %F|" "$DESKTOP"
    echo "✔ Desktop entry patched. Backup at $BACKUP"
else
    echo "⚠ No .desktop file found. If installed via Flatpak/AppImage, skip desktop patch."
fi

echo "=== Zed is now forced to run on CPU only (GPU disabled). ==="
