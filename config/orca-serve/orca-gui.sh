#!/usr/bin/env bash
# orca-gui — open the Orca GUI; pause the headless 'orca-serve' service while it is open
# and bring it back when the GUI closes. Both can't share one Orca profile.
#   no service installed/enabled -> behaves exactly like plain 'orca-ide'
#   GUI already running          -> just hands over (focuses it), touches nothing
# Overrides (for testing): ORCA_GUI_BIN, ORCA_SERVE_UNIT.
GUI=${ORCA_GUI_BIN:-/opt/Orca/orca-ide}
UNIT=${ORCA_SERVE_UNIT:-orca-serve.service}
sc() { systemctl --user "$@"; }

# Main GUI process only: Electron children carry --type=..., 'serve' has its own argv.
gui_running() { pgrep -af "^$GUI( |\$)" | grep -qv -e '--type=' -e ' serve'; }

if gui_running; then exec "$GUI" "$@"; fi

enabled=0
sc is-enabled --quiet "$UNIT" 2>/dev/null && enabled=1

restore() {
  # Wait out any lingering GUI process, then hand the profile back to the service.
  while gui_running; do sleep 1; done
  [ "$enabled" = 1 ] && sc start --no-block "$UNIT" 2>/dev/null
  return 0
}

if [ "$enabled" = 1 ]; then
  sc stop "$UNIT" 2>/dev/null          # synchronous; no-op if it isn't running
  trap restore EXIT
  trap 'exit 143' TERM HUP INT
fi

"$GUI" "$@"
