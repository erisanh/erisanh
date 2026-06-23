#!/usr/bin/env bash
# ==============================================================================
# activity-logger.sh — stream Hyprland activity events to Telegram
#
# Listens on Hyprland IPC socket2 and batches events into periodic Telegram
# messages. Flushes on a timer even when idle.
#
# Events tracked:
#   activewindow  → focused app (class + title, deduped)
#   openwindow    → new window opened
#   closewindow   → window closed
#   workspace     → workspace switched
#   fullscreen    → fullscreen toggled
#   monitoradded  → monitor hotplugged
#
# Config (shared with boot-report.sh): ~/.config/boot-report.env
#   TELEGRAM_BOT_TOKEN=...
#   TELEGRAM_CHAT_ID=...
#   ACTIVITY_FLUSH_INTERVAL=300   # seconds between sends (default 300)
#   ACTIVITY_MIN_EVENTS=3         # min events to bother sending (default 3)
# ==============================================================================
set -euo pipefail

CONFIG_FILE="${HOME}/.config/boot-report.env"
[ -f "$CONFIG_FILE" ] || { echo "activity-logger: $CONFIG_FILE not found" >&2; exit 0; }
# shellcheck source=/dev/null
source "$CONFIG_FILE"
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ] || {
  echo "activity-logger: missing credentials" >&2; exit 0; }

FLUSH_INTERVAL="${ACTIVITY_FLUSH_INTERVAL:-300}"
MIN_EVENTS="${ACTIVITY_MIN_EVENTS:-3}"
HOSTNAME_STR="$(hostname)"

# ── Helpers ───────────────────────────────────────────────────────────────────
tg_send() {
  curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "parse_mode=HTML" \
    --data-urlencode "text=$1" \
    >/dev/null 2>&1 || true
}

# ── Find Hyprland socket ──────────────────────────────────────────────────────
SIG="${HYPRLAND_INSTANCE_SIGNATURE:-}"
[ -n "$SIG" ] || SIG="$(ls /tmp/hypr/ 2>/dev/null | head -1)"
[ -n "$SIG" ] || { echo "activity-logger: no Hyprland socket found" >&2; exit 1; }
SOCKET="/tmp/hypr/${SIG}/.socket2.sock"
[ -S "$SOCKET" ] || { echo "activity-logger: socket not found: $SOCKET" >&2; exit 1; }

# ── State — plain variables, NO subshell (use socat with fd redirect) ─────────
BATCH=()
BATCH_START="$(date '+%H:%M:%S')"
LAST_FLUSH="$(date +%s)"
LAST_APP=""

flush_batch() {
  local count="${#BATCH[@]}"
  if [ "$count" -lt "$MIN_EVENTS" ]; then
    BATCH=()
    BATCH_START="$(date '+%H:%M:%S')"
    LAST_FLUSH="$(date +%s)"
    return
  fi

  local end_time msg body i
  end_time="$(date '+%H:%M:%S')"
  body=""
  for i in "${!BATCH[@]}"; do
    body="${body}${BATCH[$i]}"$'\n'
  done

  msg="📊 <b>Activity — ${HOSTNAME_STR}</b>
<b>Period:</b> ${BATCH_START} → ${end_time}  (<b>${count}</b> events)

${body}"

  [ "${#msg}" -gt 4000 ] && msg="${msg:0:3900}"$'\n<i>... (truncated)</i>'

  tg_send "$msg"

  BATCH=()
  BATCH_START="$(date '+%H:%M:%S')"
  LAST_FLUSH="$(date +%s)"
  echo "activity-logger: flushed ${count} events at ${end_time}"
}

process_event() {
  local line="$1"
  local event="${line%%>>*}"
  local data="${line#*>>}"
  local ts; ts="$(date '+%H:%M')"

  case "$event" in
    activewindow)
      local class="${data%%,*}"
      local title="${data#*,}"
      if [ -n "$class" ] && [ "$class" != "$LAST_APP" ]; then
        LAST_APP="$class"
        BATCH+=("${ts} 🪟 <b>${class}</b> — ${title:0:60}")
      fi
      ;;
    openwindow)
      local class; class="$(echo "$data" | cut -d',' -f3)"
      [ -n "$class" ] && BATCH+=("${ts} ✚ opened <b>${class}</b>")
      ;;
    closewindow)
      BATCH+=("${ts} ✖ closed a window")
      ;;
    workspace)
      BATCH+=("${ts} 📋 workspace → <b>${data}</b>")
      ;;
    fullscreen)
      [ "$data" = "1" ] \
        && BATCH+=("${ts} ⛶ fullscreen on") \
        || BATCH+=("${ts} ⛶ fullscreen off")
      ;;
    monitoradded)
      BATCH+=("${ts} 🖥 monitor added: <b>${data}</b>")
      ;;
  esac
}

# ── Main loop — use process substitution to avoid subshell scoping ────────────
now=0
echo "activity-logger: watching ${SOCKET} (flush every ${FLUSH_INTERVAL}s, min ${MIN_EVENTS} events)"

# Open socat as a file descriptor so the while loop runs in the CURRENT shell
exec 3< <(socat - "UNIX-CONNECT:${SOCKET}" 2>/dev/null)

while true; do
  # Non-blocking read with timeout = 1s so the timer can fire even when idle
  if IFS= read -r -t 1 line <&3 2>/dev/null; then
    [ -n "$line" ] && process_event "$line"
  fi

  # Timer: flush if interval elapsed
  now="$(date +%s)"
  if [ $((now - LAST_FLUSH)) -ge "$FLUSH_INTERVAL" ]; then
    flush_batch
  fi
done

exec 3<&-
