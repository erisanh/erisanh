#!/bin/bash

# === install-zed-flatpak.sh ===
# Install Zed Editor via Flatpak + fix app menu + create global 'zed' command
# Run with: sudo ./install-zed-flatpak.sh

set -e  # Exit immediately if any command fails

echo "=== Refreshing Flathub repository ==="
flatpak remote-delete flathub || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "=== Installing Zed Editor ==="
flatpak install flathub dev.zed.Zed -y

echo "=== Fixing XDG_DATA_DIRS so Zed appears in the app menu ==="
cat > /etc/profile.d/flatpak.sh <<'EOF'
# Flatpak environment - ensures apps appear in menu
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"
EOF

# Apply the change to the current session
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"

echo "=== Updating desktop database ==="
update-desktop-database || sudo update-desktop-database

echo "=== Creating global command: zed ==="
ln -sf /var/lib/flatpak/exports/bin/dev.zed.Zed /usr/local/bin/zed

echo "=== Done! Launching Zed... ==="
zed || flatpak run dev.zed.Zed
