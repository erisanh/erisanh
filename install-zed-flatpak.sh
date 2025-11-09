#!/bin/bash
# === install-zed-flatpak.sh ===
# Install Zed Editor via Flatpak + FULL fix: menu + global command + desktop shortcut
# Run: sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-flatpak.sh)"

set -e

echo "=== Refresh Flathub ==="
flatpak remote-delete flathub || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "=== Installing Zed Editor ==="
flatpak install flathub dev.zed.Zed -y

echo "=== Fixing XDG_DATA_DIRS ==="
sudo tee /etc/profile.d/flatpak.sh > /dev/null <<'EOF'
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/home/$USER/.local/share/flatpak/exports/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"
EOF
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/home/$USER/.local/share/flatpak/exports/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"

echo "=== Updating desktop database ==="
sudo update-desktop-database

echo "=== Creating global 'zed' command ==="
sudo rm -f /usr/local/bin/zed
sudo ln -sf /var/lib/flatpak/app/dev.zed.Zed/current/active/files/bin/zed /usr/local/bin/zed

echo "=== Creating Desktop shortcut ==="
cat > ~/Desktop/Zed.desktop <<'EOF'
[Desktop Entry]
Name=Zed Editor
Exec=zed %F
Icon=dev.zed.Zed
Type=Application
Categories=Development;IDE;
Terminal=false
EOF
chmod +x ~/Desktop/Zed.desktop

echo "=== All done! Launching Zed... ==="
zed


# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/erisanh/erisanh/refs/heads/main/install-zed-flatpak.sh)"
