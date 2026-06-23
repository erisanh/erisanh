#!/usr/bin/env bash
# =============================================================================
# setup-app.sh — install optional desktop apps for this machine.
#
# Every app is a self-contained function `install_<name>`. You can:
#   • run this script directly to install one / several / all apps, or
#   • `source` it from install.sh to reuse the same functions during install.
#
# Usage:
#   bash setup-app.sh                  # interactive prompt
#   bash setup-app.sh list             # list available apps
#   bash setup-app.sh bruno docker     # install specific apps
#   bash setup-app.sh all              # install every app below
#   bash setup-app.sh jetbrains        # JetBrains Toolbox (pick IDEs from it later)
#   bash setup-app.sh vscode-save      # snapshot live VSCode config back into the repo
#
# Apps:  bruno  docker  vscode  figma  jetbrains  zalo  telegram  archive  uv  nvm  fcitx5
#
# NOTE: open-design.ai is intentionally NOT included — Linux has no prebuilt
# AppImage, so both AUR variants build from source (the -git desktop build is
# ~20 min). Use the web app at https://open-design.ai instead.
#
# Package sources (verified):
#   bruno         -> AUR  bruno-bin
#   docker        -> repo docker docker-compose docker-buildx
#   vscode        -> AUR  visual-studio-code-bin   (official Microsoft build)
#                    + restores config/vscode/{settings,keybindings}.json + extensions
#   figma         -> AUR  figma-linux-bin          (defaults desktop chrome to dark theme)
#   jetbrains     -> AUR  jetbrains-toolbox        (launcher to install any JetBrains IDE)
#   zalo          -> AUR  zalo-for-linux-bin
#   telegram      -> repo telegram-desktop
#   archive       -> repo ark zip unzip 7zip unrar unarchiver
#                    (Ark adds Dolphin right-click Extract/Compress via KF6 plugins)
#   uv            -> repo uv                       (Python package + version manager)
#   nvm           -> fisher jorgebucaran/nvm.fish  (Node version manager, fish-native)
#   fcitx5        -> Vietnamese input (fcitx5-bamboo) + Super+Space toggle + autostart
# =============================================================================
set -euo pipefail

# Reuse the caller's logging helpers when sourced; otherwise define our own.
declare -F log  >/dev/null || log()  { printf '\n\033[1;32m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
declare -F info >/dev/null || info() { printf '    %s\n' "$*"; }
declare -F warn >/dev/null || warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
declare -F die  >/dev/null || die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# Repo root (works whether run directly or sourced).
SETUP_APP_REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# ---- prerequisites -----------------------------------------------------------
# Make sure yay (AUR helper) exists; build it from the AUR if missing.
ensure_yay() {
  command -v yay >/dev/null 2>&1 && return 0
  command -v pacman >/dev/null 2>&1 || die "Not Arch Linux (no pacman) — cannot install apps."
  [ "$(id -u)" -ne 0 ] || die "Do not run as root — yay must build as a normal user."
  info "yay not found — building it from the AUR…"
  sudo pacman -S --needed --noconfirm base-devel git
  local tmp; tmp="$(mktemp -d)"
  git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
  ( cd "$tmp/yay" && makepkg -si --noconfirm )
  rm -rf "$tmp"
}

# Thin wrappers so each install function stays a one-liner and reads clearly.
aur()  { ensure_yay; yay    -S --needed --noconfirm "$@" </dev/null; }   # AUR / repo via yay
repo() { sudo pacman -S --needed --noconfirm "$@" </dev/null; }          # official repo only

# =============================================================================
# App install functions
# =============================================================================
install_bruno() {
  log "Installing Bruno (API client)"
  aur bruno-bin && info "Bruno installed." || warn "Bruno install failed."
}

install_docker() {
  log "Installing Docker + Compose"
  repo docker docker-compose docker-buildx || { warn "Docker install failed."; return 1; }
  # enable --now both enables on boot AND starts the daemon now, so 'docker' is
  # usable immediately (no reboot needed to create /var/run/docker.sock).
  sudo systemctl enable --now docker.service >/dev/null 2>&1 \
    && info "docker.service enabled + started." \
    || warn "could not start docker.service — run: sudo systemctl enable --now docker"
  sudo usermod -aG docker "$(id -un)" \
    && info "added $(id -un) to the docker group — LOG OUT/IN (or 'newgrp docker') to use docker without sudo."
}

install_vscode() {
  log "Installing Visual Studio Code (official build)"
  aur visual-studio-code-bin && info "VSCode installed." || warn "VSCode install failed."

  # Restore config from the repo so a reinstalled machine keeps the same VSCode:
  # settings.json (incl. the Nerd Font terminal fix), keybindings.json, extensions.
  local vsrc="$SETUP_APP_REPO/config/vscode" vdst="$HOME/.config/Code/User"
  if [ -d "$vsrc" ]; then
    mkdir -p "$vdst"
    [ -f "$vsrc/settings.json" ]    && cp -f "$vsrc/settings.json"    "$vdst/settings.json"    && info "restored VSCode settings.json"   || true
    [ -f "$vsrc/keybindings.json" ] && cp -f "$vsrc/keybindings.json" "$vdst/keybindings.json" && info "restored VSCode keybindings.json" || true
    if [ -f "$vsrc/extensions.txt" ] && command -v code >/dev/null 2>&1; then
      info "Installing VSCode extensions from extensions.txt…"
      while read -r _ext; do
        case "$_ext" in ''|\#*) continue;; esac
        code --install-extension "$_ext" --force >/dev/null 2>&1 && info "  + $_ext" || warn "  ! $_ext failed"
      done < "$vsrc/extensions.txt"
    fi
  fi
}

# Snapshot the CURRENT live VSCode config back INTO the repo (run this after you
# tweak settings / add extensions, so the next reinstall picks them up):
#   bash setup-app.sh vscode-save
vscode_save() {
  log "Saving current VSCode config into the repo"
  local vdst="$SETUP_APP_REPO/config/vscode" vsrc="$HOME/.config/Code/User"
  mkdir -p "$vdst"
  [ -f "$vsrc/settings.json" ]    && cp -f "$vsrc/settings.json"    "$vdst/settings.json"    && info "saved settings.json"    || true
  [ -f "$vsrc/keybindings.json" ] && cp -f "$vsrc/keybindings.json" "$vdst/keybindings.json" && info "saved keybindings.json" || true
  ls -d "$HOME/.vscode/extensions"/*/ 2>/dev/null | xargs -n1 basename 2>/dev/null \
    | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+.*$//' | sort -u > "$vdst/extensions.txt"
  info "saved $(wc -l < "$vdst/extensions.txt") extensions to extensions.txt"
}

install_figma() {
  log "Installing Figma (figma-linux desktop)"
  aur figma-linux-bin && info "Figma desktop installed." || warn "Figma install failed."

  # Default the figma-linux desktop chrome to the built-in dark theme
  # (theme id 'dark-theme'). settings.json also holds runtime state, so MERGE
  # the key instead of overwriting; create a minimal file if it doesn't exist
  # yet (figma hasn't been launched). NOTE: the Figma EDITOR's own light/dark is
  # a Figma account setting (in-app Preferences → Theme), not in this file.
  local fdir="$HOME/.config/figma-linux" fset="$fdir/settings.json"
  mkdir -p "$fdir"
  if [ -f "$fset" ] && command -v jq >/dev/null 2>&1; then
    local tmp; tmp="$(mktemp)"
    jq '.theme.currentTheme = "dark-theme"' "$fset" > "$tmp" \
      && mv "$tmp" "$fset" && info "figma-linux theme defaulted to dark." \
      || { rm -f "$tmp"; warn "could not set figma dark theme."; }
  else
    cat > "$fset" <<'FIGMA'
{
  "app": { "disableThemes": false },
  "theme": { "currentTheme": "dark-theme" }
}
FIGMA
    info "figma-linux default theme set to dark (new settings.json)."
  fi
}

# NOTE: open-design.ai was intentionally dropped — Linux has no prebuilt AppImage,
# so both AUR variants build from source (the -git desktop build takes ~20 min).
# Use the web version at https://open-design.ai when needed.

install_jetbrains() {
  log "Installing JetBrains Toolbox App"
  aur jetbrains-toolbox \
    && info "JetBrains Toolbox installed — launch it, sign in, then install any IDE (IntelliJ, PyCharm, WebStorm, …) from inside it." \
    || warn "JetBrains Toolbox install failed."
}

install_zalo() {
  log "Installing Zalo desktop"
  aur zalo-for-linux-bin && info "Zalo installed." || warn "Zalo install failed."
}

install_telegram() {
  log "Installing Telegram desktop"
  repo telegram-desktop && info "Telegram installed." || warn "Telegram install failed."
}

# ---- archive manager: Ark + backends for zip / 7z / rar / tar -----------------
# On KDE Plasma 6 / KF6, Ark adds the right-click Extract / Compress entries in
# Dolphin via KFileItemAction PLUGINS (not .desktop service menus):
#   /usr/lib/qt6/plugins/kf6/kfileitemaction/extractfileitemaction.so   -> Extract
#   /usr/lib/qt6/plugins/kf6/kfileitemaction/compressfileitemaction.so  -> Compress
# Dolphin loads these automatically once Ark is installed — no manual config
# needed. We just rebuild the KDE service cache so a running Dolphin picks them
# up without a relogin. Backends give full format coverage: zip+unzip (.zip),
# 7zip (.7z, provides /usr/bin/7z), unrar (.rar), unarchiver (unar/lsar, extras).
install_archive() {
  log "Installing archive manager (Ark + zip/7z/rar backends)"
  repo ark zip unzip 7zip unrar unarchiver \
    && info "Ark + backends installed." \
    || { warn "archive tools install failed."; return 1; }
  # Refresh the KDE service cache so Dolphin shows Extract/Compress immediately.
  command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true
  info "Right-click in Dolphin now has Extract… / Compress… (restart Dolphin if open)."
}

# ---- uv: Python package + version manager (Astral) ---------------------------
install_uv() {
  log "Installing uv (Python package & version manager)"
  repo uv \
    && info "uv installed (e.g. 'uv python install 3.12', 'uv venv', 'uv pip install …')." \
    || warn "uv install failed."
}

# ---- nvm: Node version manager -----------------------------------------------
# The classic nvm is a bash/zsh shell function and does NOT work in fish — this
# machine's login shell is fish, so we install nvm.fish (jorgebucaran), which
# provides the same `nvm` command natively in fish. It needs fisher, which we
# bootstrap here if absent. (For bash too, install the AUR 'nvm' package.)
install_nvm() {
  log "Installing nvm.fish (Node version manager for fish)"
  command -v fish >/dev/null 2>&1 || { warn "fish not installed — install fish first."; return 1; }
  fish -c '
    if not functions -q fisher
      curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
      fisher install jorgebucaran/fisher
    end
    fisher install jorgebucaran/nvm.fish
  ' </dev/null \
    && info "nvm installed (fish). Use:  nvm install lts  &&  nvm use lts" \
    || warn "nvm.fish install failed — run in fish: fisher install jorgebucaran/nvm.fish"
}

# ---- Vietnamese input (fcitx5 + bamboo, Super+Space toggle, autostart) -------
install_fcitx5() {
  log "Setting up Vietnamese input (fcitx5-bamboo, Super+Space)"
  aur fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-bamboo \
    || warn "some fcitx5 packages failed (non-fatal)"

  # Input-method env vars for GTK / Qt / X11 / SDL apps (system-wide).
  sudo tee /etc/environment >/dev/null <<'ENVEOF'
# Input method — fcitx5 (Vietnamese via bamboo)
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
ENVEOF

  # Profile: English (keyboard-us) + Vietnamese (bamboo) in one group.
  mkdir -p "$HOME/.config/fcitx5"
  cat > "$HOME/.config/fcitx5/profile" <<'FCITXPROFILE'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=bamboo

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=bamboo
Layout=

[GroupOrder]
0=Default
FCITXPROFILE

  # Global config: trigger/toggle key = Super+Space (instead of the default Ctrl+Space).
  cat > "$HOME/.config/fcitx5/config" <<'FCITXCONFIG'
[Hotkey]
# Toggle / switch input method: Super + Space
TriggerKeys=Super+space
EnumerateWithTriggerKeys=True
EnumerateSkipFirst=False

[Hotkey/TriggerKeys]
0=Super+space

[Hotkey/EnumerateGroupForwardKeys]
0=Super+space

[Hotkey/EnumerateGroupBackwardKeys]
0=Super+Shift+space

[Hotkey/PrevPage]
0=Up

[Hotkey/NextPage]
0=Down

[Hotkey/PrevCandidate]
0=Shift+Tab

[Hotkey/NextCandidate]
0=Tab

[Behavior]
ActiveByDefault=False
ShareInputState=No
PreeditEnabledByDefault=True
ShowInputMethodInformation=True
CompactInputMethodInformation=True
DefaultPageSize=5
FCITXCONFIG
  info "fcitx5 configured (toggle Vietnamese ↔ English with Super+Space)."

  # Autostart fcitx5 with the Hyprland session (illogical-impulse uses execs.lua).
  local execs="$HOME/.config/hypr/hyprland/execs.lua"
  if [ -f "$execs" ]; then
    if grep -q 'fcitx5' "$execs"; then
      info "fcitx5 autostart already present in execs.lua."
    else
      # Insert the exec line right after the hyprland.start callback opens.
      sed -i '/hl.on("hyprland.start", function ()/a\
\
    -- Input method (Vietnamese via fcitx5-bamboo)\
    hl.exec_cmd("fcitx5 -d --replace")' "$execs" \
        && info "added fcitx5 autostart to execs.lua." \
        || warn "could not edit execs.lua — add 'fcitx5 -d --replace' to your Hyprland autostart manually."
    fi
  else
    warn "Hyprland execs.lua not found yet (illogical-impulse not installed?)."
    warn "After installing it, re-run to add autostart:  bash ~/erisanh/setup-app.sh fcitx5"
  fi
}

# =============================================================================
# Dispatcher — only runs when executed directly (not when sourced by install.sh)
# =============================================================================
# Ordered list used by 'all' and the interactive prompt.
SETUP_APP_ALL=(bruno docker vscode figma jetbrains zalo telegram archive uv nvm fcitx5)

setup_app_run() {
  local name="$1"
  case "$name" in
    bruno)              install_bruno ;;
    docker)             install_docker ;;
    vscode|code)        install_vscode ;;
    vscode-save|code-save) vscode_save ;;
    figma)              install_figma ;;
    jetbrains|toolbox|jetbrains-toolbox)  install_jetbrains ;;
    zalo)               install_zalo ;;
    telegram)           install_telegram ;;
    archive|ark)        install_archive ;;
    uv)                 install_uv ;;
    nvm|node)           install_nvm ;;
    fcitx5|vietnamese|vi) install_fcitx5 ;;
    *) warn "Unknown app: $name  (run 'bash setup-app.sh list')"; return 1 ;;
  esac
}

setup_app_main() {
  [ "$(id -u)" -ne 0 ] || die "Run setup-app.sh as your normal user, not root."

  # No args -> interactive prompt.
  if [ "$#" -eq 0 ]; then
    echo "Available apps: ${SETUP_APP_ALL[*]}"
    printf 'Which to install? (space-separated, or "all"): '
    read -r line || true
    [ -n "${line:-}" ] || { info "Nothing selected."; return 0; }
    # shellcheck disable=SC2086
    set -- $line
  fi

  case "${1:-}" in
    list|--list|-l) printf '%s\n' "${SETUP_APP_ALL[@]}"; return 0 ;;
    all|--all)      set -- "${SETUP_APP_ALL[@]}" ;;
  esac

  local app rc=0
  for app in "$@"; do setup_app_run "$app" || rc=1; done
  log "setup-app.sh finished."
  return "$rc"
}

# Run main only when invoked directly; do nothing when sourced.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  setup_app_main "$@"
fi
