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
#   bash setup-app.sh shortcuts        # (re)write the Hyprland app-launch keybinds
#
# Apps:  bruno  docker  vscode  figma  onlyoffice  jetbrains  zalo  telegram  teams  capcut  archive  uv  nvm  pandoc  gh  fcitx5  shortcuts
#
# Re-runs are idempotent for EVERY app: one that's already installed is NOT
# reinstalled — the run just (re)applies its config / launch keybind. A missing
# app is installed first. Launch keybinds are written only for installed GUI
# apps (docker/uv/nvm/fcitx5/archive are daemons/CLI/input-method with nothing
# to "open", so they get the install-skip but no key).
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
#   zalo          -> AUR  zalo-for-linux-bin  (+ repo fuse2: the AppImage needs
#                    libfuse.so.2 at runtime or `zalo` fails to launch)
#   telegram      -> repo telegram-desktop
#   teams         -> AUR  teams-for-linux          (open-source Electron client;
#                    Microsoft discontinued the official Linux Teams app)
#   capcut        -> web-app launcher (~/.local/bin/capcut) opening capcut.com in
#                    a Chromium-based browser (Brave) --app window; no native
#                    Linux CapCut exists, so this wraps the official web editor
#   archive       -> repo ark zip unzip 7zip unrar unarchiver
#                    (Ark adds Dolphin right-click Extract/Compress via KF6 plugins)
#   uv            -> repo uv                       (Python package + version manager)
#   nvm           -> fisher jorgebucaran/nvm.fish  (Node version manager, fish-native)
#   onlyoffice    -> AUR  onlyoffice-bin               (Calc for .xlsx/.ods/etc.)
#   fcitx5        -> Vietnamese input (fcitx5-bamboo) + Super+Space toggle + autostart
#   shortcuts     -> Hyprland app-launch keybinds (written to hypr/custom/keybinds.lua),
#                    one per INSTALLED GUI app:  Super+Alt+  B Bruno  C VSCode
#                    D Figma  E Teams  J JetBrains  O OnlyOffice  T Telegram  V CapCut  Z Zalo
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

# Idempotency helpers: skip the (re)install when the app is already present so a
# re-run only refreshes the keybinds. have_pkg = installed pacman package;
# have_cmd = launchable binary on PATH (or an absolute path to one).
have_pkg() { pacman -Qq "$1" >/dev/null 2>&1; }
have_cmd() { command -v "$1" >/dev/null 2>&1 || [ -x "$1" ]; }

# =============================================================================
# App install functions
# =============================================================================
install_bruno() {
  log "Bruno (API client)"
  if have_cmd bruno; then info "Bruno already installed — skipping install."
  else aur bruno-bin && info "Bruno installed." || warn "Bruno install failed."; fi
}

install_docker() {
  log "Docker + Compose"
  if have_cmd docker; then
    info "Docker already installed — skipping install (service/group still ensured below)."
  else
    repo docker docker-compose docker-buildx || { warn "Docker install failed."; return 1; }
  fi
  # enable --now both enables on boot AND starts the daemon now, so 'docker' is
  # usable immediately (no reboot needed to create /var/run/docker.sock).
  sudo systemctl enable --now docker.service >/dev/null 2>&1 \
    && info "docker.service enabled + started." \
    || warn "could not start docker.service — run: sudo systemctl enable --now docker"
  sudo usermod -aG docker "$(id -un)" \
    && info "added $(id -un) to the docker group — LOG OUT/IN (or 'newgrp docker') to use docker without sudo."
}

install_vscode() {
  log "Visual Studio Code (official build)"
  if have_cmd code; then info "VSCode already installed — skipping install (config still synced below)."
  else aur visual-studio-code-bin && info "VSCode installed." || warn "VSCode install failed."; fi

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
  log "Figma (figma-linux desktop)"
  if have_cmd figma-linux; then info "Figma already installed — skipping install (dark theme still applied below)."
  else aur figma-linux-bin && info "Figma desktop installed." || warn "Figma install failed."; fi

  # Default the figma-linux desktop chrome to the built-in dark theme
  # (theme id 'dark-theme'). settings.json also holds runtime state, so MERGE
  # the key instead of overwriting; create a minimal file if it doesn't exist
  # yet (figma hasn't been launched). NOTE: the Figma EDITOR's own light/dark is
  # a Figma account setting (in-app Preferences → Theme), not in this file.
  local fdir="$HOME/.config/figma-linux"
  local fset="$fdir/settings.json"
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

install_onlyoffice() {
  log "OnlyOffice Desktop Editors (spreadsheet / writer / presentation)"
  if have_cmd onlyoffice-desktopeditors; then
    info "OnlyOffice already installed — skipping install."
  else
    aur onlyoffice-bin \
      && info "OnlyOffice installed (supports .xlsx, .ods, .docx, .pptx, …)." \
      || warn "OnlyOffice install failed."
  fi
}

install_jetbrains() {
  log "JetBrains Toolbox App"
  if have_cmd jetbrains-toolbox; then
    info "JetBrains Toolbox already installed — skipping install."
  else
    aur jetbrains-toolbox \
      && info "JetBrains Toolbox installed — launch it, sign in, then install any IDE (IntelliJ, PyCharm, WebStorm, …) from inside it." \
      || warn "JetBrains Toolbox install failed."
  fi
}

install_zalo() {
  log "Zalo desktop"
  if have_cmd zalo; then info "Zalo already installed — skipping install."
  else aur zalo-for-linux-bin && info "Zalo installed." || warn "Zalo install failed."; fi
  # Zalo ships as an AppImage that needs FUSE (libfuse.so.2) AT RUNTIME, but the
  # AUR package doesn't pull it in — without it `zalo` dies instantly with
  # "dlopen(): error loading libfuse.so.2 / AppImages require FUSE to run", so the
  # launcher/keybind appears to "do nothing". Ensure fuse2 is present.
  if ! have_pkg fuse2; then
    repo fuse2 && info "fuse2 installed (AppImage runtime needed by Zalo)." \
      || warn "fuse2 install failed — Zalo will not launch until 'fuse2' is installed."
  else
    info "fuse2 already present (Zalo AppImage runtime)."
  fi
}

install_telegram() {
  log "Telegram desktop"
  # The telegram-desktop package installs the binary as 'Telegram' (capital T),
  # NOT 'telegram-desktop'.
  if have_cmd Telegram; then info "Telegram already installed — skipping install."
  else repo telegram-desktop && info "Telegram installed." || warn "Telegram install failed."; fi
}

# Microsoft discontinued the official Linux Teams client, so we use the
# community 'teams-for-linux' (an open-source Electron wrapper around the
# Teams web app — the de-facto Linux Teams on Arch). Binary: teams-for-linux.
install_teams() {
  log "Microsoft Teams (teams-for-linux)"
  if have_cmd teams-for-linux; then info "MS Teams already installed — skipping install."
  else aur teams-for-linux && info "MS Teams installed." || warn "MS Teams install failed."; fi
}

# CapCut (ByteDance) ships NO native Linux client — only Windows/macOS/web/mobile.
# We install a thin web-app launcher: a Chromium-based browser opened in --app
# (standalone-window) mode pointing at the official CapCut web editor, plus a
# .desktop entry so it shows in the app launcher. Binary: ~/.local/bin/capcut.
install_capcut() {
  log "CapCut (web app — no native Linux client exists)"
  local capbin="$HOME/.local/bin/capcut"
  if have_cmd "$capbin"; then info "CapCut launcher already present — skipping install."; return 0; fi
  # Find a Chromium-based browser that supports --app (Brave is this machine's default).
  local browser=""
  local b; for b in brave brave-browser chromium google-chrome-stable microsoft-edge-stable; do
    command -v "$b" >/dev/null 2>&1 && { browser="$b"; break; }
  done
  if [ -z "$browser" ]; then
    warn "No Chromium-based browser found (brave/chromium/chrome) — install one first."
    warn "CapCut web needs --app mode; re-run after a browser is installed:  bash ~/erisanh/setup-app.sh capcut"
    return 1
  fi
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
  cat > "$capbin" <<CAPCUT
#!/usr/bin/env bash
# CapCut web-app launcher (ByteDance ships no native Linux client).
exec $browser --app=https://www.capcut.com --class=capcut --name=capcut "\$@"
CAPCUT
  chmod +x "$capbin"
  cat > "$HOME/.local/share/applications/capcut.desktop" <<'CAPDESK'
[Desktop Entry]
Type=Application
Name=CapCut
Comment=CapCut video editor (web app)
Exec=capcut
Icon=video-editor
Terminal=false
Categories=AudioVideo;Video;
StartupWMClass=capcut
CAPDESK
  info "CapCut web launcher installed ($capbin → opens in $browser)."
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
  log "Archive manager (Ark + zip/7z/rar backends)"
  if have_cmd ark; then
    info "Ark already installed — skipping install (Dolphin cache still refreshed below)."
  else
    repo ark zip unzip 7zip unrar unarchiver \
      && info "Ark + backends installed." \
      || { warn "archive tools install failed."; return 1; }
  fi
  # Refresh the KDE service cache so Dolphin shows Extract/Compress immediately.
  command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true
  info "Right-click in Dolphin now has Extract… / Compress… (restart Dolphin if open)."
}

# ---- uv: Python package + version manager (Astral) ---------------------------
install_uv() {
  log "uv (Python package & version manager)"
  if have_cmd uv; then info "uv already installed — skipping install."
  else repo uv \
    && info "uv installed (e.g. 'uv python install 3.12', 'uv venv', 'uv pip install …')." \
    || warn "uv install failed."; fi
}

# ---- gh: GitHub CLI ----------------------------------------------------------
install_gh() {
  log "gh (GitHub CLI)"
  if have_cmd gh; then info "gh already installed — skipping install."
  else repo github-cli \
    && info "gh installed. Authenticate with: gh auth login" \
    || warn "gh install failed."; fi
}

# ---- pandoc: universal document converter ------------------------------------
install_pandoc() {
  log "pandoc (universal document converter)"
  if have_cmd pandoc; then info "pandoc already installed — skipping install."
  else repo pandoc \
    && info "pandoc installed (e.g. 'pandoc input.md -o output.pdf')." \
    || warn "pandoc install failed."; fi
}

# ---- nvm: Node version manager -----------------------------------------------
# The classic nvm is a bash/zsh shell function and does NOT work in fish — this
# machine's login shell is fish, so we install nvm.fish (jorgebucaran), which
# provides the same `nvm` command natively in fish. It needs fisher, which we
# bootstrap here if absent. (For bash too, install the AUR 'nvm' package.)
install_nvm() {
  log "nvm.fish (Node version manager for fish)"
  command -v fish >/dev/null 2>&1 || { warn "fish not installed — install fish first."; return 1; }
  if fish -c 'functions -q nvm' 2>/dev/null; then
    info "nvm.fish already installed — skipping install."
    return 0
  fi
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
  log "Vietnamese input (fcitx5-bamboo, Super+Space)"
  if have_pkg fcitx5 && have_pkg fcitx5-bamboo; then
    info "fcitx5 + bamboo already installed — skipping install (config still applied below)."
  else
    aur fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-bamboo \
      || warn "some fcitx5 packages failed (non-fatal)"
  fi

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

# ---- Cloudflare WARP (warp-cli, for the right-sidebar toggle) ---------------
install_cloudflare_warp() {
  log "Cloudflare WARP (warp-cli)"
  if have_cmd warp-cli; then
    info "cloudflare-warp already installed — skipping install (service still ensured below)."
  else
    aur cloudflare-warp-bin \
      && info "cloudflare-warp installed." \
      || { warn "cloudflare-warp install failed."; return 1; }
  fi
  sudo systemctl enable --now warp-svc.service >/dev/null 2>&1 \
    && info "warp-svc enabled + started." \
    || warn "could not start warp-svc — run: sudo systemctl enable --now warp-svc"
}

# ---- Hyprland app-launch keybinds --------------------------------------------
# illogical-impulse leaves hypr/custom/keybinds.lua for user-defined binds and
# never overwrites it, so we manage our launch keys inside a marked block there
# (idempotent: the whole block is regenerated on every run, never duplicated).
#
# Single source of truth: "app | check-cmd | keybind | launch-cmd | label".
# A key is only written when its check-cmd is present, so an app you haven't
# installed never leaves a dead keybind. All chosen Super+Alt letters are free
# in the default illogical-impulse binds (M=mute-mic, F=fullscreen are avoided).
# Only GUI apps you'd "open" get a launch key — docker/uv/nvm/fcitx5/archive are
# daemons / CLI tools / input-method / Dolphin integration with nothing to launch.
#   B Bruno  C VSCode  D Figma  E MS Teams  J JetBrains  O OnlyOffice  T Telegram  V CapCut  Z Zalo
SETUP_APP_SHORTCUTS=(
  "bruno|bruno|SUPER + ALT + B|bruno|Bruno"
  "vscode|code|SUPER + ALT + C|code|VSCode"
  "figma|figma-linux|SUPER + ALT + D|figma-linux|Figma"
  "teams|teams-for-linux|SUPER + ALT + E|teams-for-linux|MS Teams"
  "jetbrains|jetbrains-toolbox|SUPER + ALT + J|jetbrains-toolbox|JetBrains Toolbox"
  "onlyoffice|onlyoffice-desktopeditors|SUPER + ALT + O|onlyoffice-desktopeditors|OnlyOffice"
  "telegram|Telegram|SUPER + ALT + T|Telegram|Telegram"
  "capcut|$HOME/.local/bin/capcut|SUPER + ALT + V|$HOME/.local/bin/capcut|CapCut"
  "zalo|zalo|SUPER + ALT + Z|zalo|Zalo"
)

install_shortcuts() {
  log "Setting up Hyprland app-launch keybinds (for installed apps only)"
  local kb="$HOME/.config/hypr/custom/keybinds.lua"
  if [ ! -d "$(dirname "$kb")" ]; then
    warn "hypr/custom not found yet (illogical-impulse not installed?) — skipping."
    warn "After installing it, re-run:  bash ~/erisanh/setup-app.sh shortcuts"
    return 1
  fi
  touch "$kb"
  # Drop any previous managed block so re-runs don't pile up duplicate binds.
  if grep -q '>>> erisanh app shortcuts >>>' "$kb"; then
    sed -i '/>>> erisanh app shortcuts >>>/,/<<< erisanh app shortcuts <<</d' "$kb"
    sed -i -e :a -e '/^\n*$/{$d;N;ba}' "$kb"   # trim trailing blank lines
  fi
  # Regenerate the block, emitting a bind line only for apps actually installed.
  local entry key check keybind cmd label wrote=""
  {
    echo '-- >>> erisanh app shortcuts >>> (managed by setup-app.sh — edit there, not here)'
    for entry in "${SETUP_APP_SHORTCUTS[@]}"; do
      IFS='|' read -r key check keybind cmd label <<<"$entry"
      if have_cmd "$check"; then
        printf 'hl.bind("%s", hl.dsp.exec_cmd("%s"), {description = "Launch %s"})\n' "$keybind" "$cmd" "$label"
        wrote="$wrote $label"
      fi
    done
    echo '-- <<< erisanh app shortcuts <<<'
  } >> "$kb"
  [ -n "$wrote" ] && info "app keybinds written for:$wrote" \
                  || info "no shortcut apps installed yet — block left empty."
  # Live-reload so the keys work without a relogin (no-op if Hyprland isn't up).
  command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 \
    && info "Hyprland config reloaded." || true
}

# =============================================================================
# Dispatcher — only runs when executed directly (not when sourced by install.sh)
# =============================================================================
# Ordered list used by 'all' and the interactive prompt.
SETUP_APP_ALL=(bruno docker vscode figma onlyoffice jetbrains zalo telegram teams capcut archive uv nvm pandoc gh fcitx5 cloudflare-warp shortcuts)

setup_app_run() {
  local name="$1"
  case "$name" in
    bruno)              install_bruno ;;
    docker)             install_docker ;;
    vscode|code)        install_vscode ;;
    vscode-save|code-save) vscode_save ;;
    figma)              install_figma ;;
    onlyoffice)         install_onlyoffice ;;
    jetbrains|toolbox|jetbrains-toolbox)  install_jetbrains ;;
    zalo)               install_zalo ;;
    telegram)           install_telegram ;;
    teams|msteams|ms-teams|teams-for-linux) install_teams ;;
    capcut)             install_capcut ;;
    shortcuts|keybinds|keys) install_shortcuts ;;
    archive|ark)        install_archive ;;
    uv)                 install_uv ;;
    nvm|node)           install_nvm ;;
    pandoc)             install_pandoc ;;
    gh|github-cli)      install_gh ;;
    fcitx5|vietnamese|vi) install_fcitx5 ;;
    cloudflare-warp|cloudflare|warp) install_cloudflare_warp ;;
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

  local app rc=0 touched_shortcut="" did_shortcuts=""
  for app in "$@"; do
    case "$app" in
      shortcuts|keybinds|keys) did_shortcuts=1 ;;
      bruno|vscode|code|figma|onlyoffice|teams|msteams|ms-teams|teams-for-linux|jetbrains|toolbox|jetbrains-toolbox|telegram|capcut|zalo) touched_shortcut=1 ;;
    esac
    setup_app_run "$app" || rc=1
  done
  # If we processed a shortcut-bearing app, sync its launch key now (the app was
  # installed-if-needed above). Skip when 'shortcuts' was requested explicitly
  # (already synced). Non-fatal if the Hyprland config isn't present yet.
  if [ -n "$touched_shortcut" ] && [ -z "$did_shortcuts" ]; then
    install_shortcuts || true
  fi
  log "setup-app.sh finished."
  return "$rc"
}

# Run main only when invoked directly; do nothing when sourced.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  setup_app_main "$@"
fi
