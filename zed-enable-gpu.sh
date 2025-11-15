#!/usr/bin/env bash
# zed-enable-gpu.sh - Restore GPU mode for Zed on Ubuntu 20.04.6
# Usage: bash zed-enable-gpu.sh

set -e

WRAPPER="/usr/local/bin/zed-no-gpu"
DESKTOP="/usr/share/applications/zed.desktop"
BACKUP="$DESKTOP.bak"

echo "=== Enabling GPU for Zed ==="

# Restore desktop entry
if [ -f "$BACKUP" ]; then
    echo "Restoring $DESKTOP from backup..."
    sudo mv "$BACKUP" "$DESKTOP"
    echo "✔ Desktop entry restored."
else
    echo "⚠ No backup .desktop found. Skipping restore."
fi

# Remove wrapper
if [ -f "$WRAPPER" ]; then
    echo "Removing wrapper script $WRAPPER..."
    sudo rm -f "$WRAPPER"
    echo "✔ Wrapper removed."
else
    echo "⚠ Wrapper not found. Nothing to remove."
fi

echo "=== Zed will now use GPU normally. ==="
