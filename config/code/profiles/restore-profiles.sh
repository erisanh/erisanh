#!/usr/bin/env bash
# Recreate VSCode profiles and install their extensions on a new machine (stable `code`).
# Run: bash restore-profiles.sh   (requires `visual-studio-code-bin` installed)
set -euo pipefail

CODE="${CODE_BIN:-code}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v "$CODE" >/dev/null 2>&1; then
  echo "Command '$CODE' not found. Install visual-studio-code-bin first (or set CODE_BIN)." >&2
  exit 1
fi

for d in "$DIR"/*/; do
  name="$(basename "$d")"
  list="$d/extensions.txt"
  [ -f "$list" ] || { echo "== $name: no extensions.txt, skipping"; continue; }
  echo "== Profile: $name =="
  # --profile <name> creates the profile if missing, then installs extensions into it
  while IFS= read -r ext; do
    [ -n "$ext" ] || continue
    echo "  + $ext"
    "$CODE" --profile "$name" --install-extension "$ext" --force >/dev/null || echo "    ! failed: $ext"
  done < "$list"
done

echo "Done. Open VSCode and pick a profile in the bottom-left. settings/keybindings use the shared default (symlinked)."
