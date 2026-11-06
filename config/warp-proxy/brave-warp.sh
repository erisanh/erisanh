#!/usr/bin/env bash
# brave-warp — Brave in its OWN profile; only the blocked-site allowlist goes through the local
# WARP DoH proxy (warp-doh-proxy), everything else in this window — and every other app on the
# machine, Claude CLI included — keeps going direct.
#
#   brave-warp [URL…]            open Brave (WARP)
#   brave-warp --headless=new --dump-dom URL     any Brave flags pass straight through
#
# Env: WARP_DOH_PROXY (127.0.0.1:40001)  WARP_DOH_HOSTS (~/.config/warp-doh-proxy/hosts)
#      BRAVE_WARP_PROFILE (~/.config/brave-warp)
set -euo pipefail

PROXY="${WARP_DOH_PROXY:-127.0.0.1:40001}"
HOSTS="${WARP_DOH_HOSTS:-$HOME/.config/warp-doh-proxy/hosts}"
PROFILE="${BRAVE_WARP_PROFILE:-$HOME/.config/brave-warp}"
die() { echo "brave-warp: $*" >&2; exit 1; }

browser=""
for b in brave brave-browser chromium google-chrome-stable; do
  command -v "$b" >/dev/null 2>&1 && { browser="$b"; break; }
done
[ -n "$browser" ] || die "no Chromium-based browser found (brave/chromium/chrome)"

# 1. WARP must be in PROXY mode. In its default 'warp' mode `warp-cli connect` tunnels the whole machine
#    (Claude CLI, the bot, Telegram…) — never connect it like that from here.
if command -v warp-cli >/dev/null 2>&1; then
  settings="$(warp-cli --accept-tos settings list 2>/dev/null || true)"
  grep -q "Mode: WarpProxy" <<<"$settings" \
    || die "WARP is not in proxy mode — run:  warp-cli mode proxy   (otherwise connecting would tunnel the whole machine)"
  if ! warp-cli --accept-tos status 2>/dev/null | grep -q "Connected"; then
    warp-cli --accept-tos connect >/dev/null
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      warp-cli --accept-tos status 2>/dev/null | grep -q "Connected" && break
      sleep 1
    done
  fi
fi

# 2. The local DoH proxy must be up.
if ! (exec 3<>"/dev/tcp/${PROXY%:*}/${PROXY##*:}") 2>/dev/null; then
  systemctl --user start warp-doh-proxy.service 2>/dev/null || true
  sleep 1
fi

# 3. PAC: allowlisted domains → the proxy, everything else DIRECT. Passed inline as a data: URL —
#    Brave/Chromium ignores a file:// PAC given on the command line (checked: no connection ever
#    reached the proxy), and an inline PAC also needs no file to keep in sync.
mkdir -p "$PROFILE"
[ -r "$HOSTS" ] || die "allowlist not found: $HOSTS (run: bash ~/erisanh/setup-app.sh warp-proxy)"
pac="$(
  echo "function FindProxyForURL(url, host) {"
  echo "  host = host.toLowerCase(); var d = ["
  sed -e 's/#.*//' -e 's/[[:space:]]//g' -e 's/^\.//' "$HOSTS" | grep -v '^$' | sed -e 's/.*/    "&",/'
  echo "  ];"
  echo "  for (var i = 0; i < d.length; i++)"
  echo "    if (host === d[i] || dnsDomainIs(host, \".\" + d[i])) return \"PROXY $PROXY\";"
  echo "  return \"DIRECT\";"
  echo "}"
)"
pac_url="data:application/x-ns-proxy-autoconfig;base64,$(printf '%s' "$pac" | base64 -w0)"

exec "$browser" --user-data-dir="$PROFILE" --class=brave-warp --proxy-pac-url="$pac_url" "$@"
