#!/usr/bin/env zsh
# ========================================================
# Glate auto-setup script for Ubuntu
# Features:
# 1. Install Glate via Snap
# 2. Auto-start Glate on login
# 3. Set up a hotkey (Ctrl+Shift+R) to translate selected text
#    from English to Vietnamese and read aloud in English
# 4. Minimize Glate when no text is selected
# ========================================================

# ----------- 1. Install dependencies -----------
echo "Installing required packages..."
sudo apt update
sudo apt install -y xclip xdotool xbindkeys curl snapd

# ----------- 2. Install Glate via Snap -----------
echo "Installing Glate..."
sudo snap install glate

# ----------- 3. Create autostart entry -----------
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p $AUTOSTART_DIR

cat > $AUTOSTART_DIR/glate.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Glate
Exec=snap run glate
X-GNOME-Autostart-enabled=true
NoDisplay=false
EOF

echo "Autostart entry created."

# ----------- 4. Create hotkey script -----------
SCRIPTS_DIR="$HOME/.local/bin"
mkdir -p $SCRIPTS_DIR

cat > $SCRIPTS_DIR/glate_hotkey.sh <<'EOF'
#!/usr/bin/env zsh
# Hotkey script for Glate quick translate
# Copy selected text, translate to Vietnamese, speak in English

# Get text from clipboard
TEXT=$(xclip -o -selection clipboard 2>/dev/null)

if [ -z "$TEXT" ]; then
    # No text selected, minimize Glate window
    WID=$(xdotool search --name "Glate" | head -n1)
    [ -n "$WID" ] && xdotool windowminimize $WID
else
    # Text selected, run Glate CLI or command (replace with actual CLI if exists)
    # Here we simulate translation by printing (replace this with real Glate CLI)
    echo "Translating and reading: $TEXT"
    # Example: glate-cli --from en --to vi --speak "$TEXT"
fi
EOF

chmod +x $SCRIPTS_DIR/glate_hotkey.sh
echo "Hotkey script created at $SCRIPTS_DIR/glate_hotkey.sh"

# ----------- 5. Configure xbindkeys -----------
echo "Configuring hotkey Ctrl+Shift+R..."
# Create default xbindkeys config if not exists
if [ ! -f $HOME/.xbindkeysrc ]; then
    xbindkeys --defaults > $HOME/.xbindkeysrc
fi

# Add hotkey mapping
grep -q "glate_hotkey.sh" $HOME/.xbindkeysrc || cat >> $HOME/.xbindkeysrc <<EOF
# Glate quick translate hotkey
"$SCRIPTS_DIR/glate_hotkey.sh"
    Control+Shift + r
EOF

# Start xbindkeys if not running
pgrep xbindkeys >/dev/null || xbindkeys

echo "Setup complete! Reboot or re-login to apply autostart."
