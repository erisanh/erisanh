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
#                (install as a systemd user service for ongoing monitoring)
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
FAILED_VSCODE_FILE="${HOME}/.dotfiles-failed-vscode-extensions.txt"
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

collect_hardware_info() {
  # CPU: model + core count + max freq
  local cpu cores freq
  cpu=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null         | sed 's/model name\s*:\s*//'         | sed 's/(R)\|(TM)//g'         | xargs)
  cores=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "?")
  freq=$(awk '/cpu MHz/{sum+=$4; n++} END{if(n) printf "%.0f MHz", sum/n}'          /proc/cpuinfo 2>/dev/null || echo "")
  printf '  <b>CPU:</b> %s (%s cores%s)
'     "${cpu:-unknown}" "$cores" "${freq:+ @ $freq}"

  # RAM: used / total
  local mem_total mem_avail mem_used
  mem_total=$(awk '/MemTotal/{printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null)
  mem_avail=$(awk '/MemAvailable/{printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null)
  mem_used=$(awk -v t="$mem_total" -v a="$mem_avail" 'BEGIN{printf "%.1f", t-a}')
  printf '  <b>RAM:</b> %s GiB used / %s GiB total
' "$mem_used" "$mem_total"

  # GPU: prefer lspci, fallback to /sys
  local gpu
  gpu=$(lspci 2>/dev/null         | grep -i "VGA\|3D\|Display"         | sed 's/.*: //'         | sed 's/ (rev [0-9a-f]*//'         | head -3         | sed 's/^/    /')
  [ -n "$gpu" ] && printf '  <b>GPU:</b>
%s
' "$gpu"                 || printf '  <b>GPU:</b> (lspci not available)
'

  # Motherboard / product name
  local board
  board=$(cat /sys/class/dmi/id/product_name 2>/dev/null           || cat /sys/class/dmi/id/board_name 2>/dev/null           || echo "unknown")
  local vendor
  vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null | xargs || echo "")
  printf '  <b>Board:</b> %s %s
' "$vendor" "$board"

  # BIOS version
  local bios
  bios=$(cat /sys/class/dmi/id/bios_version 2>/dev/null | xargs || echo "unknown")
  printf '  <b>BIOS:</b> %s
' "$bios"

  # Storage: all block devices, size + model
  local storage
  storage=$(lsblk -dno NAME,SIZE,MODEL,TRAN 2>/dev/null             | grep -v "^loop\|^sr"             | awk '{printf "    %s: %s %s (%s)
", $1, $2, $3, $4}'             | head -5)
  [ -n "$storage" ] && printf '  <b>Storage:</b>
%s
' "$storage"

  # Display resolution(s)
  local displays
  displays=$(hyprctl monitors -j 2>/dev/null              | python3 -c "
import sys, json
try:
    mons = json.load(sys.stdin)
    for m in mons:
        w = m.get('width', '?')
        h = m.get('height', '?')
        hz = m.get('refreshRate', 0)
        name = m.get('name', '?')
        print(f'    {name}: {w}x{h}@{hz:.0f}Hz')
except: pass
" 2>/dev/null)
  [ -n "$displays" ] && printf '  <b>Display:</b>
%s
' "$displays"

  # Keyboard connected via Bluetooth/USB (lsusb if available)
  local kb
  kb=$(lsusb 2>/dev/null        | grep -i "keyboard\|Dareu\|HID"        | sed 's/Bus [0-9]* Device [0-9]*: ID [0-9a-f:]*  */    /'        | head -3)
  [ -n "$kb" ] && printf '  <b>HID devices:</b>
%s
' "$kb"
}

# ── Collectors ────────────────────────────────────────────────────────────────
collect_failed_units() {
  systemctl --failed --no-legend --no-pager 2>/dev/null \
    | awk '{print "  \xe2\x97\x8f " $1}' | head -20 \
    || echo "  (none)"
}

collect_failed_packages() {
  if [ -f "$FAILED_PKG_FILE" ]; then
    awk '{print "  \xe2\x9c\x97 " $0}' "$FAILED_PKG_FILE" | head -30
  else
    echo "  (none)"
  fi
}

collect_vscode_failures() {
  # Reads ~/.dotfiles-failed-vscode-extensions.txt written by restore-profiles.sh.
  # Format per line: <profile>:<extension-id>
  if [ ! -f "$FAILED_VSCODE_FILE" ]; then
    echo "  (none)"
    return
  fi
  local count
  count=$(wc -l < "$FAILED_VSCODE_FILE")
  echo "  ${count} extension(s) failed:"
  while IFS=: read -r profile ext; do
    echo "    [${profile}] ${ext}"
  done < "$FAILED_VSCODE_FILE"
}

collect_firstboot_errors() {
  if [ -f "$FIRSTBOOT_LOG" ]; then
    grep -i -E "error|fail|warn|!|✗" "$FIRSTBOOT_LOG" \
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

collect_npm_audit() {
  # Scan npm projects under common dirs for high/critical vulnerabilities.
  # Silently skips if npm is not installed or no package.json found.
  command -v npm >/dev/null 2>&1 || { echo "  (npm not installed)"; return; }

  local results="" dir high critical out
  local search_dirs=("$HOME/src" "$HOME/projects" "$HOME/work" "$HOME/erisanh")

  for base in "${search_dirs[@]}"; do
    [ -d "$base" ] || continue
    while IFS= read -r dir; do
      out=$(cd "$dir" && npm audit --json 2>/dev/null || true)
      high=$(echo "$out" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); \
          print(d.get('metadata',{}).get('vulnerabilities',{}).get('high',0))" 2>/dev/null || echo 0)
      critical=$(echo "$out" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); \
          print(d.get('metadata',{}).get('vulnerabilities',{}).get('critical',0))" 2>/dev/null || echo 0)
      if [ "${high:-0}" -gt 0 ] || [ "${critical:-0}" -gt 0 ]; then
        local label="${dir/#$HOME/\~}"
        results="${results}  $(printf '\xf0\x9f\x93\x81') ${label} — high: ${high}, critical: ${critical}\n"
      fi
    done < <(find "$base" -maxdepth 3 -name "package.json" \
               ! -path "*/node_modules/*" -printf '%h\n' 2>/dev/null | sort -u)
  done

  if [ -z "$results" ]; then
    echo "  (no vulnerabilities found)"
  else
    printf '%b' "$results"
  fi
}

# ── Build message ─────────────────────────────────────────────────────────────
build_message() {
  local mode="$1"
  local icon title

  case "$mode" in
    --firstboot) icon="$(printf '\xf0\x9f\x9a\x80')"; title="First-boot provision complete" ;;
    --provision) icon="$(printf '\xf0\x9f\x94\xa7')"; title="Manual provision complete" ;;
    --boot)      icon="$(printf '\xe2\x9a\xa1')";      title="System boot report" ;;
    *)           icon="$(printf '\xf0\x9f\x93\x8b')"; title="Boot report" ;;
  esac

  # Collect once, reuse in message and for status icon
  local failed_units errors warnings
  failed_units="$(collect_failed_units)"
  errors="$(collect_journal_errors)"
  warnings="$(collect_journal_warnings)"

  # Status icon: red = failed units, yellow = errors only, green = clean
  local status_icon="$(printf '\xe2\x9c\x85')"
  if echo "$failed_units" | grep -q "$(printf '\xe2\x97\x8f')"; then
    status_icon="$(printf '\xf0\x9f\x94\xb4')"
  elif ! echo "$errors" | grep -q "(none)"; then
    status_icon="$(printf '\xe2\x9a\xa0\xef\xb8\x8f')"
  fi

  printf '%s <b>%s %s</b>\n' "$status_icon" "$icon" "$title"
  printf '<b>Host:</b> %s\n' "$HOSTNAME_STR"
  printf '<b>Time:</b> %s\n' "$TIMESTAMP"
  printf '<b>Uptime:</b> %s\n' "$(uptime_str)"
  printf '<b>Kernel:</b> %s\n' "$(kernel_str)"
  printf '<b>Disk /:</b> %s\n' "$(disk_usage)"

  section "$(printf '\xf0\x9f\x96\xa5') Hardware"
  collect_hardware_info

  section "$(printf '\xe2\x9d\x8c') Failed systemd units"
  printf '%s\n' "$failed_units"

  if [ "$mode" != "--boot" ]; then
    section "$(printf '\xf0\x9f\x93\xa6') Failed packages (yay)"
    collect_failed_packages
    section "$(printf '\xf0\x9f\x94\xb4') Provision errors (from log)"
    collect_firstboot_errors
    section "$(printf '\xf0\x9f\x9f\xa5') VSCode extension failures"
    collect_vscode_failures
  fi

  section "$(printf '\xf0\x9f\x94\xb4') Errors (journal)"
  printf '%s\n' "$errors"

  section "$(printf '\xe2\x9a\xa0\xef\xb8\x8f') Warnings (journal)"
  printf '%s\n' "$warnings"

  section "$(printf '\xf0\x9f\x94\x92') npm audit (high/critical only)"
  collect_npm_audit
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
  tg_file "Full firstboot log — ${HOSTNAME_STR} ${TIMESTAMP}" "$FIRSTBOOT_LOG"
fi

echo "boot-report: sent to Telegram."
