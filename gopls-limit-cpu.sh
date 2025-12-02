#!/bin/bash
# gopls-limit-cpu.sh
# Permanently limit all gopls processes via cpulimit + systemd user service

set -e

LIMIT="${1:-30}"
SERVICE="gopls-cpulimit.service"
FILE="$HOME/.config/systemd/user/$SERVICE"

create() {
    local pct="$1"
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$FILE" <<EOF
[Unit]
Description=Limit gopls to ${pct}% total CPU
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/cpulimit -l ${pct} -b -z -e gopls
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now "$SERVICE" >/dev/null 2>&1
    echo "gopls limited to ≤ ${pct}% CPU"
}

remove() {
    systemctl --user disable --now "$SERVICE" >/dev/null 2>&1 || true
    rm -f "$FILE"
    systemctl --user daemon-reload
    echo "gopls CPU limit removed"
}

case "$LIMIT" in
    off|disable|remove) remove ;;
    ''|[0-9]* ) create "$LIMIT" ;;
    *) echo "Usage: $(basename "$0") [10-100]|off" ; exit 1 ;;
esac
esac
