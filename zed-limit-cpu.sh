#!/bin/bash
# zed-limit-cpu.sh
# Limit or remove CPU limit for Zed Editor via cpulimit (systemd user service)

set -e

LIMIT="${1:-60}"
SERVICE_NAME="zed-cpulimit.service"
SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME"

create_or_update_service() {
    local percent="$1"
    mkdir -p "$HOME/.config/systemd/user"

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Limit Zed Editor to ${percent}% total CPU usage
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/cpulimit -l ${percent} -b -z -e zed
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now "$SERVICE_NAME" >/dev/null 2>&1
    echo "Zed Editor limited to ≤ ${percent}% CPU"
}

remove_service() {
    systemctl --user disable --now "$SERVICE_NAME" >/dev/null 2>&1 || true
    rm -f "$SERVICE_FILE"
    systemctl --user daemon-reload
    echo "CPU limit removed from Zed Editor"
}

case "$LIMIT" in
    off|disable|remove) remove_service ;;
    ''|[0-9]|[1-9][0-9]|100) create_or_update_service "$LIMIT" ;;
    *) 
        echo "Usage: zed-cpu [10-100]|off"
        echo "  zed-cpu      → 60% (default)"
        echo "  zed-cpu 40   → limit to 40%"
        echo "  zed-cpu off  → remove limit"
        exit 1
        ;;
esac
