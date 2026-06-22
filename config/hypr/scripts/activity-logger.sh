#!/usr/bin/env bash
# ==============================================================================
# activity-logger.sh — stream Hyprland activity events to Telegram
#
# Listens on the Hyprland IPC socket2 and batches events into periodic
# Telegram messages so you can monitor app usage and workspace activity
# remotely without being spammed per-event.
#
# Events tracked:
#   activewindow  → app focused (class + title, deduped)
#   openwindow    → new window opened
#   closewindow   → window closed
#   workspace     → workspace switched
#   fullscreen    → fullscreen toggled
#
# Config: reads ~/.config/boot-report.env (shared with boot-report.sh)
#   TELEGRAM_BOT_TOKEN=...
#   TELEGRAM_CHAT_ID=...
#
# Optional overrides in the same file:
#   ACTIVITY_FLUSH_INTERVAL=300   # seconds between flushes (default: 300)
#   ACTIVITY_MIN_EVENTS=5         # min events before sending (default: 5)
#
# Managed by systemd user service activity-logger.service.
# ==============================================================================
set -euo pipefail

CONFIG_FILE="${HOME}/.config/boot-report.env"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "activity-logger: $CONFIG_FILE not found — exiting." >&2
  exit 0
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
  echo "activity-logger: missing credentials in $CONFIG_FILE" >&2
  exit 0
fi

FLUSH_INTERVAL="${ACTIVITY_FLUSH_INTERVAL:-300}"
MIN_EVENTS="${ACTIVITY_MIN_EVENTS:-5}"
HOSTNAME_STR="$(hostname)"

# ── Helpers ───────────────────────────────────────────────────────────────────
tg_send() {
  curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d parse_mode="HTML" \
    --data-urlencode "text=$1" \
    > /dev/null 2>&1 || true
}

# ── Find Hyprland socket ──────────────────────────────────────────────────────
find_socket() {
  local sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
  if [ -z "$sig" ]; then
    sig=$(ls /tmp/hypr/ 2>/dev/null | head -1)
  fi
  [ -n "$sig" ] || { echo "activity-logger: no Hyprland instance found" >&2; exit 1; }
  echo "/tmp/hypr/${sig}/.socket2.sock"
}

SOCKET="$(find_socket)"
[ -S "$SOCKET" ] || { echo "activity-logger: socket not found: $SOCKET" >&2; exit 1; }

# ── Batch state (files — avoids subshell scoping issues) ─────────────────────
BATCH_FILE="$(mktemp /tmp/activity-batch.XXXXXX)"
BATCH_START_FILE="$(mktemp /tmp/activity-start.XXXXXX)"
date '+%H:%M:%S' > "$BATCH_START_FILE"
LAST_FLUSH="$(date +%s)"
LAST_APP_FILE="$(mktemp /tmp/activity-lastapp.XXXXXX)"

cleanup() { rm -f "$BATCH_FILE" "$BATCH_START_FILE" "$LAST_APP_FILE"; }
trap cleanup EXIT

append_event() { printf '%s\n' "$1" >> "$BATCH_FILE"; }

flush_batch() {
  local count
  count=$(wc -l < "$BATCH_FILE" 2>/dev/null || echo 0)

  if [ "$count" -lt "$MIN_EVENTS" ]; then
    # Not enough events yet — reset timer but keep batch
    LAST_FLUSH="$(date +%s)"
    return
  fi

  local start end_time
  start="$(cat "$BATCH_START_FILE")"
  end_time="$(date '+%H:%M:%S')"

  local header
  header="$(printf '\xf0\x9f\x93\x8a') <b>Activity — ${HOSTNAME_STR}</b>
<b>Period:</b> ${start} → ${end_time}  (<b>${count}</b> events)
"
  local body
  body="$(cat "$BATCH_FILE")"

  local msg="${header}${body}"
  if [ "${#msg}" -gt 4000 ]; then
    msg="${msg:0:3900}
<i>... (truncated)</i>"
  fi

  tg_send "$msg"

  # Reset batch
  > "$BATCH_FILE"
  date '+%H:%M:%S' > "$BATCH_START_FILE"
  LAST_FLUSH="$(date +%s)"
}

# ── Main loop ─────────────────────────────────────────────────────────────────
echo "activity-logger: watching $SOCKET (flush every ${FLUSH_INTERVAL}s, min ${MIN_EVENTS} events)"

socat - "UNIX-CONNECT:${SOCKET}" | while IFS= read -r line; do
  [ -n "$line" ] || continue

  event="${line%%>>*}"
  data="${line#*>>}"
  ts="$(date '+%H:%M')"

  case "$event" in
    activewindow)
      class="${data%%,*}"
      title="${data#*,}"
      last_app="$(cat "$LAST_APP_FILE" 2>/dev/null || true)"
      if [ -n "$class" ] && [ "$class" != "$last_app" ]; then
        echo "$class" > "$LAST_APP_FILE"
        append_event "${ts} $(printf '\xf0\x9f\xaa\x9f') <b>${class}</b> — ${title:0:60}"
      fi
      ;;
    openwindow)
      class="$(echo "$data" | cut -d',' -f3)"
      [ -n "$class" ] && append_event "${ts} $(printf '\xe2\x9c\x9a') opened <b>${class}</b>"
      ;;
    closewindow)
      append_event "${ts} $(printf '\xe2\x9c\x96') window closed"
      ;;
    workspace)
      append_event "${ts} $(printf '\xf0\x9f\x93\x8b') workspace $(printf '\xe2\x86\x92') <b>${data}</b>"
      ;;
    fullscreen)
      if [ "$data" = "1" ]; then
        append_event "${ts} $(printf '\xe2\x9b\xb6') fullscreen on"
      else
        append_event "${ts} $(printf '\xe2\x9b\xb6') fullscreen off"
      fi
      ;;
  esac

  # Check if flush interval elapsed
  now="$(date +%s)"
  if [ $((now - LAST_FLUSH)) -ge "$FLUSH_INTERVAL" ]; then
    flush_batch
  fi
done

flush_batch
