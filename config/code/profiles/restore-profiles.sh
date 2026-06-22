#!/usr/bin/env bash
# Recreate VSCode profiles and install their extensions on a new machine (stable `code`).
# Run: bash restore-profiles.sh   (requires `visual-studio-code-bin` installed)
#
# Fix (2026-06): VSCode --profile <name> fails with "Profile 'x' not found"
# when running headless (no active Wayland/X11 session) because the profile
# registry hasn't been written yet. Pre-seeding profiles.json solves this.
set -euo pipefail

CODE="${CODE_BIN:-code}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v "$CODE" >/dev/null 2>&1; then
  echo "Command '$CODE' not found. Install visual-studio-code-bin first (or set CODE_BIN)." >&2
  exit 1
fi

# ---- Pre-seed profiles.json so VSCode knows the profiles exist ----
# Without this, --profile <name> fails with "Profile 'x' not found" during
# headless first-boot provisioning (no display session active yet).
PROFILES_SRC="$DIR/profiles.json"
PROFILES_DEST="$HOME/.config/Code/User/profiles.json"
if [ -f "$PROFILES_SRC" ]; then
  mkdir -p "$HOME/.config/Code/User"
  if [ ! -f "$PROFILES_DEST" ]; then
    cp "$PROFILES_SRC" "$PROFILES_DEST"
    echo "Pre-seeded $PROFILES_DEST from repo."
  else
    echo "(profiles.json already exists — keeping existing. Delete and re-run to reset.)"
  fi
fi

# ---- Install extensions per profile ----
# Failed extensions are written to ~/.dotfiles-failed-vscode-extensions.txt
# so boot-report.sh can include them in the Telegram notification.
FAILED_LOG="$HOME/.dotfiles-failed-vscode-extensions.txt"
rm -f "$FAILED_LOG"   # start fresh each run

FAILED_TOTAL=0
for d in "$DIR"/*/; do
  name="$(basename "$d")"
  list="$d/extensions.txt"
  [ -f "$list" ] || { echo "== $name: no extensions.txt, skipping"; continue; }
  echo "== Profile: $name =="

  FAILED_EXTS=()
  while IFS= read -r ext; do
    [ -n "$ext" ] || continue
    [[ "$ext" == \#* ]] && continue   # skip comment lines
    echo "  + $ext"
    if "$CODE" --profile "$name" --install-extension "$ext" --force 2>/dev/null; then
      : # success
    else
      echo "    ! failed: $ext"
      FAILED_EXTS+=("$ext")
      FAILED_TOTAL=$((FAILED_TOTAL + 1))
      # Write profile:extension pairs for boot-report.sh to pick up
      echo "${name}:${ext}" >> "$FAILED_LOG"
    fi
  done < "$list"

  if ((${#FAILED_EXTS[@]} > 0)); then
    echo "  => ${#FAILED_EXTS[@]} extension(s) failed in '$name'."
    echo "     Re-run after logging into Hyprland (display session required)."
  fi
done

echo ""
if ((FAILED_TOTAL > 0)); then
  echo "Done with $FAILED_TOTAL failure(s). Re-run after first Hyprland login."
  echo "Failed extensions logged to: $FAILED_LOG"
else
  echo "Done. All extensions installed successfully."
  rm -f "$FAILED_LOG"   # no failures — clean up
fi
echo "Open VSCode and pick a profile in the bottom-left."
