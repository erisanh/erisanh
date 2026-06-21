#!/usr/bin/env bash
# ==============================================================================
# anim-preset.sh — switch Hyprland animation preset (plan.theme.md §2)
# ==============================================================================
#
#   default  -> Material 3 expressive (smooth, battery-safe)
#   playful  -> bouncy + rotating gradient border (more GPU / battery)
#   off      -> animations disabled (max battery)
#
# Usage: anim-preset.sh [default|playful|off|cycle]   (no arg = cycle)
#
# Writes ~/.cache/hypr/anim-preset then reloads Hyprland. appearance.lua reads
# that file on (re)load. If a reload doesn't re-evaluate the Lua config on your
# setup, log out/in once for the change to take effect.

set -euo pipefail

file="$HOME/.cache/hypr/anim-preset"
mkdir -p "$(dirname "$file")"

cur="default"
if [ -f "$file" ]; then
	cur="$(tr -d '[:space:]' <"$file" 2>/dev/null || echo default)"
fi
case "$cur" in
	default | playful | off) ;;
	*) cur="default" ;;
esac

case "${1:-cycle}" in
	default | playful | off) next="$1" ;;
	cycle)
		case "$cur" in
			default) next="playful" ;;
			playful) next="off" ;;
			*) next="default" ;;
		esac
		;;
	*)
		echo "usage: ${0##*/} [default|playful|off|cycle]" >&2
		exit 1
		;;
esac

printf '%s\n' "$next" >"$file"
hyprctl reload >/dev/null 2>&1 || true

if command -v notify-send >/dev/null 2>&1; then
	notify-send -a Hyprland "Animation preset" "Now: $next" || true
fi
echo "$next"
