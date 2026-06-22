#!/usr/bin/env bash
# ==============================================================================
# boot-report.sh — send boot/provision log to Telegram
#
# Called at the end of `install.sh --firstboot` (or --provision) to report
# results remotely as soon as the machine has network — no display required.
#
# Usage:
#   bash boot-report.sh [--firstboot|--provision|--boot]
#
# Modes:
#   --firstboot  full provision summary + errors (default when called from install.sh)
#   --provision  same as --firstboot but labelled "manual provision"
#   --boot       systemd failed units + journal errors/warnings after a normal reboot
#
# Config: read from ~/.config/boot-report.env (never committed to git)
#   TELEGRAM_BOT_TOKEN=123456:ABC...
#   TELEGRAM_CHAT_ID=9876543
#
# Create a bot: https://t.me/BotFather → /newbot
# Get chat_id:  send any message to the bot, then open
#   https://api.telegram.org/bot<TOKEN>/getUpdates
# ==============================================================================
set -euo pipefail

MODE="${1:---firstboot}"
CONFIG_FILE="${HOME}/.config/boot-report.env"
FIRSTBOOT_LOG="/var/log/dotfiles-firstboot.log"
FAILED_PKG_FILE="${HOME}/.dotfiles-failed-packages.txt"
HOSTNAME_STR="$(hostname)"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# ── Load credentials ──────────────────────────────────────────────────────────
if [ ! -f "$CONFIG_FILE" ]; then
  echo "boot-report: $CONFIG_FILE not found — skipping remote report." >&2
  exit 0
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
  echo "boot-report: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID missing in $CONFIG_FILE" >&2
  exit 0
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
tg_send() {
  local text="$1"
  curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d parse_mode="HTML" \
    --data-urlencode "text=${text}" \
    > /dev/null
}

tg_file() {
  local caption="$1" filepath="$2"
  [ -f "$filepath" ] || return 0
  curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
    -F chat_id="${TELEGRAM_CHAT_ID}" \
    -F caption="${caption}" \
    -F document=@"${filepath}" \
    > /dev/null
}

section() { printf '\n<b>%s</b>\n' "$1"; }
uptime_str() { uptime -p 2>/dev/null || uptime; }
kernel_str()  { uname -r; }
disk_usage()  { df -h / 2>/dev/null | awk 'NR==2{print $3 " used / " $2 " total (" $5 ")"}'; }

# ── Collectors ────────────────────────────────────────────────────────────────
collect_failed_units() {
  systemctl --failed --no-legend --no-pager 2>/dev/null \
    | awk '{print "  ● " $1}' | head -20 \
    || echo "  (none)"
}

collect_failed_packages() {
  if [ -f "$FAILED_PKG_FILE" ]; then
    awk '{print "  ✗ " $0}' "$FAILED_PKG_FILE" | head -30
  else
    echo "  (none)"
  fi
}

collect_firstboot_errors() {
  if [ -f "$FIRSTBOOT_LOG" ]; then
    grep -i -E "error|fail|warn|✗|!" "$FIRSTBOOT_LOG" \
      | grep -v "^$\|install.sh\|backup" \
      | tail -40 \
      | sed 's/^/  /' \
      || echo "  (none)"
  else
    echo "  (firstboot log not found)"
  fi
}

collect_journal_errors() {
  # priority 0-3: emerg, alert, crit, err
  journalctl -b -p err --no-pager --no-hostname -q 2>/dev/null \
    | grep -v -E "Failed to load.*theme|use-gl.*Electron|Bluetooth|hci|rfkill" \
    | tail -20 \
    | sed 's/^/  /' \
    || echo "  (none)"
}

collect_journal_warnings() {
  # priority 4: warning only (excludes err+ already shown above)
  journalctl -b -p warning..warning --no-pager --no-hostname -q 2>/dev/null \
    | grep -v -E "use-gl.*Electron|deprecated|Bluetooth|hci|rfkill|Failed to load.*theme|NetworkManager.*device" \
    | tail -15 \
    | sed 's/^/  /' \
    || echo "  (none)"
}

# ── Build message ─────────────────────────────────────────────────────────────
build_message() {
  local mode="$1"
  local icon title

  case "$mode" in
    --firstboot) icon="🚀"; title="First-boot provision complete" ;;
    --provision) icon="🔧"; title="Manual provision complete" ;;
    --boot)      icon="⚡"; title="System boot report" ;;
    *)           icon="📋"; title="Boot report" ;;
  esac

  # Collect once, reuse in message and for status icon
  local failed_units errors warnings
  failed_units="$(collect_failed_units)"
  errors="$(collect_journal_errors)"
  warnings="$(collect_journal_warnings)"

  # Status icon: 🔴 failed units, ⚠️ errors only, ✅ clean
  local status_icon="✅"
  if echo "$failed_units" | grep -q "●"; then
    status_icon="🔴"
  elif ! echo "$errors" | grep -q "(none)"; then
    status_icon="⚠️"
  fi

  cat <<MSG
${status_icon} <b>${icon} ${title}</b>
<b>Host:</b> ${HOSTNAME_STR}
<b>Time:</b> ${TIMESTAMP}
<b>Uptime:</b> $(uptime_str)
<b>Kernel:</b> $(kernel_str)
<b>Disk /:</b> $(disk_usage)
$(section "❌ Failed systemd units")
${failed_units}
MSG

  if [ "$mode" != "--boot" ]; then
    cat <<MSG
$(section "📦 Failed packages (yay)")
$(collect_failed_packages)
$(section "🔴 Provision errors (from log)")
$(collect_firstboot_errors)
MSG
  fi

  cat <<MSG
$(section "🔴 Errors (journal)")
${errors}
$(section "⚠️ Warnings (journal)")
${warnings}
MSG
}

# ── Send ──────────────────────────────────────────────────────────────────────
MSG="$(build_message "$MODE")"

# Telegram message limit is 4096 chars — truncate if needed
if [ "${#MSG}" -gt 4000 ]; then
  MSG="${MSG:0:3900}
<i>... (truncated — see attached log for full output)</i>"
fi

tg_send "$MSG"

# Attach full firstboot log in provision modes
if [ "$MODE" != "--boot" ] && [ -f "$FIRSTBOOT_LOG" ]; then
  tg_file "📄 Full firstboot log — ${HOSTNAME_STR} ${TIMESTAMP}" "$FIRSTBOOT_LOG"
fi

echo "boot-report: sent to Telegram."
