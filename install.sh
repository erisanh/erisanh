#!/usr/bin/env bash
# =============================================================================
# install.sh — reinstall this machine from the dotfiles in this repo.
#
# Two stages, auto-detected:
#
#   STAGE 1  BOOTSTRAP  (run from the Arch live ISO, as root)
#     Wipes a disk you confirm by name, then fully installs Arch:
#       • GPT + UEFI: 1 GiB ESP (FAT32) + Btrfs root with @,@home,@log,@pkg,@snapshots
#       • pacstrap base system, fstab, timezone/locale/hostname, initramfs
#       • create your user, set passwords, systemd-boot (UEFI) bootloader
#       • copy this repo into your new home and arm a first-boot service
#     Then it AUTO-REBOOTS and runs Stage 2 on first boot — no manual step.
#
#   STAGE 2  PROVISION  (runs on the installed system)
#     • install an AUR helper (yay), then every package in pacman.txt
#     • symlink all dotfiles from this repo into $HOME (existing files backed up)
#     • restore the 6 VSCode profiles + extensions
#     • enable services + configure zram (plan section 8)
#
# Usage:
#   From the Arch ISO:   bash install.sh            (auto -> bootstrap)
#   On an installed box: bash install.sh            (auto -> provision)
#   Force a stage:       bash install.sh --bootstrap | --provision
#
# Defaults are already baked in for THIS machine (no prompts except the disk
# confirmation): user 'iubeha', disk '/dev/nvme0n1', password '123123' for both
# the user and root. Any of these can be overridden via env vars:
#   DISK, USER_NAME, USER_PASSWORD, ROOT_PASSWORD, HOSTNAME, TIMEZONE, LOCALE, KEYMAP
#
#   Override example:
#     DISK=/dev/sda USER_PASSWORD='...' ROOT_PASSWORD='...' bash install.sh
#
#   WARNING: '123123' is a weak default password — change it after install with
#   `passwd` and `sudo passwd root`.
#
# SAFETY:
#   • Bootstrap runs with NO typed confirmation: `bash install.sh` will wipe
#     $DISK after a 5-second countdown, then AUTO-REBOOT. Press Ctrl-C during a
#     countdown to abort (nothing is touched on the disk before the first one).
#   • Passwords (default or pre-seeded) are handed to the chroot only as base64
#     in /root/install.env, applied with chpasswd, then that file is deleted
#     immediately after configuration — no password is left on disk.
# =============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\n\033[1;32m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# =============================================================================
# STAGE 1 — BOOTSTRAP (disk wipe + partition + pacstrap + base config)
# =============================================================================
bootstrap() {
  [ "$(id -u)" -eq 0 ]              || die "Bootstrap must run as root from the Arch live ISO."
  command -v pacstrap >/dev/null    || die "pacstrap not found — run this from the Arch live ISO."
  [ -d /sys/firmware/efi ]          || die "Not booted in UEFI mode — this installer only does UEFI/systemd-boot."

  # ---- configuration: defaults detected for THIS machine; override via env ----
  local HOSTNAME="${HOSTNAME:-arch}"
  local TIMEZONE="${TIMEZONE:-Asia/Ho_Chi_Minh}"
  local LOCALE="${LOCALE:-en_US.UTF-8}"
  local KEYMAP="${KEYMAP:-us}"
  local USER_NAME="${USER_NAME:-iubeha}"          # this machine's user
  local DISK="${DISK:-/dev/nvme0n1}"              # this machine's only disk (238 GB NVMe SK hynix)
  # NOTE: 123123 is a weak default password for both the user and root — change it
  # after the install with `passwd` (and `sudo passwd root`).
  local UPW="${USER_PASSWORD:-123123}"
  local RPW="${ROOT_PASSWORD:-123123}"

  # ---- target disk ----
  log "Detected disks:"
  lsblk -dpno NAME,SIZE,MODEL | grep -vE 'loop|/dev/sr' || true
  info "Target disk: $DISK   (override with DISK=/dev/... if this is wrong)"
  [ -b "$DISK" ] || die "Not a block device: $DISK"

  # ---- last-chance warning (auto-continues; no typing needed) ----
  warn "EVERYTHING on $DISK will be PERMANENTLY ERASED."
  warn "Starting in 5s — press Ctrl-C now to abort."
  for i in 5 4 3 2 1; do printf '\r    continuing in %ds ' "$i"; sleep 1; done; printf '\r%30s\r\n' ' '

  [ -n "$UPW" ] && [ -n "$RPW" ] || die "Passwords must not be empty."

  # ---- partition naming (nvme/mmc need a 'p' before the number) ----
  local P=""; case "$DISK" in *nvme*|*mmcblk*|*loop*) P="p";; esac
  local ESP="${DISK}${P}1" ROOTP="${DISK}${P}2"

  timedatectl set-ntp true || true

  log "Partitioning $DISK (GPT: 1 GiB ESP + Btrfs root)"
  wipefs -af "$DISK"
  sgdisk --zap-all "$DISK"
  sgdisk -n1:0:+1GiB -t1:ef00 -c1:EFI   "$DISK"
  sgdisk -n2:0:0     -t2:8300 -c2:root  "$DISK"
  partprobe "$DISK"; sleep 1

  log "Formatting"
  mkfs.fat -F32 -n EFI "$ESP"
  mkfs.btrfs -f -L arch "$ROOTP"

  log "Creating Btrfs subvolumes"
  mount "$ROOTP" /mnt
  local sv; for sv in @ @home @log @pkg @snapshots; do btrfs subvolume create "/mnt/$sv"; done
  umount /mnt

  local OPTS="noatime,compress=zstd:3,ssd,space_cache=v2,discard=async"
  mount -o "subvol=@,$OPTS" "$ROOTP" /mnt
  mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots,boot}
  mount -o "subvol=@home,$OPTS"      "$ROOTP" /mnt/home
  mount -o "subvol=@log,$OPTS"       "$ROOTP" /mnt/var/log
  mount -o "subvol=@pkg,$OPTS"       "$ROOTP" /mnt/var/cache/pacman/pkg
  mount -o "subvol=@snapshots,$OPTS" "$ROOTP" /mnt/.snapshots
  mount "$ESP" /mnt/boot

  log "Installing base system (pacstrap)"
  pacstrap -K /mnt base linux linux-firmware base-devel intel-ucode btrfs-progs \
                   efibootmgr networkmanager sudo git vim

  genfstab -U /mnt >> /mnt/etc/fstab

  log "Copying this repo into /home/$USER_NAME/erisanh"
  mkdir -p "/mnt/home/$USER_NAME/erisanh"
  cp -a "$REPO/." "/mnt/home/$USER_NAME/erisanh/"

  # ---- hand config values to the chroot script via a file (base64 for passwords) ----
  {
    printf 'USER_NAME=%q\n' "$USER_NAME"
    printf 'HOSTNAME=%q\n'  "$HOSTNAME"
    printf 'TIMEZONE=%q\n'  "$TIMEZONE"
    printf 'LOCALE=%q\n'    "$LOCALE"
    printf 'KEYMAP=%q\n'    "$KEYMAP"
    printf 'USER_PW_B64=%s\n' "$(printf '%s' "$UPW" | base64 -w0)"
    printf 'ROOT_PW_B64=%s\n' "$(printf '%s' "$RPW" | base64 -w0)"
    printf 'ROOT_UUID=%s\n' "$(blkid -s UUID -o value "$ROOTP")"
  } > /mnt/root/install.env
  chmod 600 /mnt/root/install.env

  cat > /mnt/root/chroot-setup.sh <<'CHROOT'
#!/usr/bin/env bash
set -euo pipefail
source /root/install.env

# time / locale / console
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc
grep -q "^$LOCALE UTF-8" /etc/locale.gen || echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE"   > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# hostname / hosts
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# initramfs
mkinitcpio -P

# accounts
printf 'root:%s\n' "$(echo "$ROOT_PW_B64" | base64 -d)" | chpasswd
id "$USER_NAME" &>/dev/null || \
  useradd -m -G wheel,video,audio,storage,input,network -s /bin/bash "$USER_NAME"
printf '%s:%s\n' "$USER_NAME" "$(echo "$USER_PW_B64" | base64 -d)" | chpasswd
chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME"

# sudo: wheel can sudo; plus a TEMP passwordless rule so first-boot provisioning
# is unattended. Stage 2 deletes 99-dotfiles-install when it finishes.
echo '%wheel ALL=(ALL:ALL) ALL'            > /etc/sudoers.d/10-wheel
echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL"  > /etc/sudoers.d/99-dotfiles-install
chmod 440 /etc/sudoers.d/10-wheel /etc/sudoers.d/99-dotfiles-install

# bootloader (UEFI) — systemd-boot (Dell Inspiron 5593 TPM workaround: GRUB's
# hardcoded TPM module crashes on this firmware before it ever reads grub.cfg).
bootctl install
# Dell BIOS only auto-boots the EFI fallback path when no NVRAM entry exists,
# so also drop the loader at /EFI/BOOT/BOOTX64.EFI.
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/BOOT/BOOTX64.EFI
mkdir -p /boot/loader/entries
cat > /boot/loader/entries/arch.conf <<BOOTENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw rootflags=subvol=@ quiet
BOOTENTRY
cat > /boot/loader/loader.conf <<BOOTLOADER
default arch.conf
timeout 3
BOOTLOADER

# networking on next boot
systemctl enable NetworkManager

# arm Stage 2 to run automatically once the network is up after first boot
# Telegram credentials are fetched automatically from private Gist inside
# provision() — no need to pass them through the service environment.
cat > /etc/systemd/system/dotfiles-firstboot.service <<UNIT
[Unit]
Description=First-boot dotfiles provisioning (Stage 2 of install.sh)
Wants=network-online.target
After=network-online.target NetworkManager-wait-online.service

[Service]
Type=oneshot
User=$USER_NAME
Environment=HOME=/home/$USER_NAME
WorkingDirectory=/home/$USER_NAME/erisanh
ExecStart=/bin/bash /home/$USER_NAME/erisanh/install.sh --firstboot
StandardOutput=append:/var/log/dotfiles-firstboot.log
StandardError=append:/var/log/dotfiles-firstboot.log
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
UNIT
systemctl enable dotfiles-firstboot.service
systemctl enable NetworkManager-wait-online.service || true
CHROOT

  log "Configuring the installed system (arch-chroot)"
  arch-chroot /mnt bash /root/chroot-setup.sh

  # scrub the password file, then unmount
  rm -f /mnt/root/install.env /mnt/root/chroot-setup.sh
  umount -R /mnt

  log "Base install complete — rebooting into the new system."
  cat <<EOF

Stage 2 (packages + dotfiles + VSCode profiles) runs automatically on first boot.
If you use Wi-Fi, connect after login so it can finish (wired DHCP needs nothing).
Watch it with:   journalctl -u dotfiles-firstboot -f
                  tail -f /var/log/dotfiles-firstboot.log

Rebooting in 5s — press Ctrl-C to stay in the live environment, then remove the media.
EOF
  for i in 5 4 3 2 1; do printf '\r    rebooting in %ds ' "$i"; sleep 1; done; printf '\n'
  systemctl reboot
}

# =============================================================================
# STAGE 2 — PROVISION (packages + dotfiles + profiles + services)
# Runs on the installed system; also invoked by the first-boot service.
# =============================================================================
provision() {
  local FIRSTBOOT="${1:-no}"
  local ME; ME="$(id -un)"
  [ "$(id -u)" -ne 0 ] || die "Provision must run as your normal user, not root."
  command -v pacman >/dev/null 2>&1 || die "pacman not found — this only supports Arch Linux."
  ping -c1 -W3 archlinux.org >/dev/null 2>&1 || \
    die "No internet. Connect first (e.g. 'nmtui'), then re-run. (First-boot will retry on next boot.)"

  local TS BACKUP
  TS="$(date +%Y%m%d-%H%M%S)"; BACKUP="$HOME/.dotfiles-backup/$TS"
  log "Provisioning from: $REPO"
  info "Replaced files are backed up to: $BACKUP"

  # ---- Telegram boot-report credentials ----
  # Credentials are fetched automatically from a private GitHub Gist.
  # Resolution order (first match wins):
  #   1. ~/.config/boot-report.env already exists → use as-is (idempotent)
  #   2. Env vars TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID are set → write file
  #   3. Auto-fetch from private Gist → write boot-report.env + chmod 600
  local BOOT_REPORT_ENV="$HOME/.config/boot-report.env"
  local GIST_URL="https://gist.githubusercontent.com/erisanh/698339687f4ef296dbf886a7dff20b1f/raw/boot-report.env"
  mkdir -p "$HOME/.config"

  if [ -f "$BOOT_REPORT_ENV" ]; then
    info "boot-report.env already exists — skipping fetch."
  elif [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    printf "TELEGRAM_BOT_TOKEN=%s\nTELEGRAM_CHAT_ID=%s\n" \
      "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" > "$BOOT_REPORT_ENV"
    chmod 600 "$BOOT_REPORT_ENV"
    info "Telegram credentials saved from env vars."
  else
    info "Fetching Telegram credentials from private Gist..."
    if curl -fsSL "$GIST_URL" -o "$BOOT_REPORT_ENV" 2>/dev/null; then
      chmod 600 "$BOOT_REPORT_ENV"
      info "boot-report.env fetched OK."
    else
      warn "Could not fetch boot-report.env (non-fatal — no Telegram report will be sent)."
      rm -f "$BOOT_REPORT_ENV"
    fi
  fi

  # ---- 1. yay (AUR helper) ----
  log "Ensuring base-devel, git and yay are present"
  sudo pacman -S --needed --noconfirm base-devel git
  if ! command -v yay >/dev/null 2>&1; then
    info "Building yay from the AUR…"
    local tmp; tmp="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
    ( cd "$tmp/yay" && makepkg -si --noconfirm )
    rm -rf "$tmp"
  else
    info "yay already installed."
  fi

  # ---- 2. install everything in pacman.txt (official repos + AUR) ----
  # Resilient by design: a single flaky AUR package (a moved mirror, a slow
  # font download) must NEVER abort the whole provision. We do one fast batch
  # pass, then retry whatever is still missing one-by-one, and report the rest
  # instead of dying — so the desktop (Hyprland/SDDM/…) always comes up.
  log "Installing packages from pacman.txt"
  local PKGS; mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$REPO/pacman.txt")
  info "${#PKGS[@]} packages requested."

  # pre-empt the classic pipewire-jack vs jack2 conflict (jack2 gets pulled in
  # by some stacks; pipewire-jack replaces it and --noconfirm would just abort).
  if pacman -Qq jack2 >/dev/null 2>&1; then
    info "removing conflicting jack2 (pipewire-jack replaces it)"
    sudo pacman -Rdd --noconfirm jack2 || true
  fi

  # fast batch pass — tolerate failures (the individual retry below recovers)
  yay -S --needed --noconfirm "${PKGS[@]}" </dev/null || \
    warn "batch install hit errors — retrying the missing packages individually"

  # second pass: install anything still missing one at a time, collect failures
  local FAILED=() p
  for p in "${PKGS[@]}"; do
    if pacman -Qq -- "$p" >/dev/null 2>&1; then continue; fi   # already present
    yay -S --needed --noconfirm -- "$p" </dev/null || FAILED+=("$p")
  done
  if ((${#FAILED[@]})); then
    warn "${#FAILED[@]} package(s) could not be installed — the rest of the system is fine:"
    printf '      - %s\n' "${FAILED[@]}"
    printf '%s\n' "${FAILED[@]}" > "$HOME/.dotfiles-failed-packages.txt"
    warn "list saved to ~/.dotfiles-failed-packages.txt — install later with: yay -S <pkg>"
  else
    info "all packages installed."
  fi

  # ---- 3. deploy dotfiles via symlink (backing up anything real) ----
  link() {
    local src="$1" dest="$2"
    [ -e "$src" ] || { warn "missing in repo, skipped: $src"; return; }
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then return; fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      mkdir -p "$BACKUP/$(dirname "${dest#"$HOME"/}")"
      mv "$dest" "$BACKUP/${dest#"$HOME"/}"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    info "linked ${dest/#$HOME/~}"
  }

  log "Linking dotfiles into \$HOME"
  mkdir -p "$HOME/.config"
  local path name
  for path in "$REPO"/config/* "$REPO"/config/.[!.]*; do
    [ -e "$path" ] || continue
    name="$(basename "$path")"
    case "$name" in
      .gitconfig) link "$path" "$HOME/.gitconfig" ;;   # home dotfile
      code)       : ;;                                  # handled below
      *)          link "$path" "$HOME/.config/$name" ;;
    esac
  done
  link "$REPO/nvim"                "$HOME/.config/nvim"
  link "$REPO/quickshell"          "$HOME/.config/quickshell"
  # systemd user units (boot-report.service, etc.)
  mkdir -p "$HOME/.config/systemd/user"
  for svc in "$REPO"/config/systemd/user/*.service "$REPO"/config/systemd/user/*.timer; do
    [ -e "$svc" ] || continue
    link "$svc" "$HOME/.config/systemd/user/$(basename "$svc")"
  done

  # ---- 4. VSCode: shared settings/keybindings + restore profiles ----
  log "Setting up VSCode (stable)"
  mkdir -p "$HOME/.config/Code/User"
  link "$REPO/config/code/settings.json"    "$HOME/.config/Code/User/settings.json"
  link "$REPO/config/code/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
  if command -v code >/dev/null 2>&1; then
    bash "$REPO/config/code/profiles/restore-profiles.sh"
  else
    warn "'code' not found — open VSCode once, then run config/code/profiles/restore-profiles.sh"
  fi

  # ---- 4b. Hyprland scrolling-layout plugin (hyprscrolling via hyprpm) ----
  # compositor.lua uses layout="scrolling", provided by the official
  # hyprscrolling plugin. hyprpm builds it from source against the installed
  # Hyprland. Best-effort + non-fatal: if the build fails here (hyprpm can be
  # finicky headless), Hyprland just falls back to dwindle and you can retry
  # after first login with:  hyprpm update && hyprpm enable hyprscrolling
  # The plugin is loaded each session by 'hyprpm reload -n' in autostart.lua.
  if command -v hyprpm >/dev/null 2>&1 && command -v Hyprland >/dev/null 2>&1; then
    log "Building the hyprscrolling layout plugin (hyprpm)"
    hyprpm update </dev/null >/dev/null 2>&1 || warn "hyprpm update failed — retry after first login"
    hyprpm add https://github.com/hyprwm/hyprland-plugins </dev/null >/dev/null 2>&1 || true
    if hyprpm enable hyprscrolling </dev/null >/dev/null 2>&1; then
      info "hyprscrolling enabled"
    else
      warn "could not enable hyprscrolling now — after first login run:"
      warn "    hyprpm update && hyprpm enable hyprscrolling"
      warn "(until then the scrolling layout falls back to dwindle)"
    fi
  else
    warn "hyprpm/Hyprland not present — scrolling layout will fall back to dwindle"
  fi

  # ---- 5. enable services ----
  log "Enabling system services"
  enable_unit() {
    if pacman -Qq "$2" >/dev/null 2>&1; then
      sudo systemctl enable "$1" >/dev/null 2>&1 && info "enabled $1" || warn "could not enable $1"
    fi
  }
  enable_unit NetworkManager.service        networkmanager
  enable_unit bluetooth.service             bluez
  enable_unit sddm.service                  sddm
  enable_unit docker.service                docker
  enable_unit cronie.service                cronie
  enable_unit power-profiles-daemon.service power-profiles-daemon
  if pacman -Qq docker >/dev/null 2>&1; then
    sudo usermod -aG docker "$ME" && info "added $ME to the docker group (re-login to apply)"
  fi

  # ---- boot-report systemd user service ----
  # Runs boot-report.sh --boot after every login so Telegram receives
  # a summary of failed units, journal errors and warnings on each boot.
  # Symlinked via the dotfiles link step; just needs to be enabled here.
  local BOOT_REPORT_SVC="$HOME/.config/systemd/user/boot-report.service"
  local ACTIVITY_SVC="$HOME/.config/systemd/user/activity-logger.service"
  systemctl --user daemon-reload 2>/dev/null || true
  for _svc in boot-report.service activity-logger.service; do
    _svc_path="$HOME/.config/systemd/user/${_svc}"
    if [ -f "$_svc_path" ]; then
      systemctl --user enable "$_svc" 2>/dev/null \
        && info "enabled ${_svc} (user)" \
        || warn "could not enable ${_svc} (non-fatal)"
    else
      warn "${_svc} not found — skipping."
    fi
  done

  # ---- 6. zram (plan section 8) ----
  log "Configuring zram"
  if pacman -Qq zram-generator >/dev/null 2>&1 && [ ! -f /etc/systemd/zram-generator.conf ]; then
    sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'ZRAM'
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
ZRAM
    info "wrote /etc/systemd/zram-generator.conf"
  else
    info "zram already configured or zram-generator not installed — skipped."
  fi

  # ---- first-boot finalisation: switch shell, then disarm and re-secure sudo ----
  if [ "$FIRSTBOOT" = "yes" ]; then
    log "Finalising first-boot provisioning"
    if command -v fish >/dev/null 2>&1; then
      sudo chsh -s /usr/bin/fish "$ME" && info "login shell set to fish"
    fi
    sudo systemctl disable dotfiles-firstboot.service >/dev/null 2>&1 || true
    sudo rm -f /etc/systemd/system/dotfiles-firstboot.service
    sudo rm -f /etc/sudoers.d/99-dotfiles-install   # restore password-protected sudo
    info "first-boot service removed; passwordless sudo revoked."

    # ---- 7. remote boot report (Telegram) ----
    # Sends a summary of errors/failures to Telegram so you can debug
    # a headless first-boot without needing to be at the machine.
    # Requires ~/.config/boot-report.env with TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID.
    # See config/hypr/scripts/boot-report.sh for setup instructions.
    local REPORT_SCRIPT="$HOME/.config/hypr/scripts/boot-report.sh"
    if [ -f "$REPORT_SCRIPT" ] && [ -f "$HOME/.config/boot-report.env" ]; then
      log "Sending boot report to Telegram"
      bash "$REPORT_SCRIPT" --firstboot || warn "boot-report failed (non-fatal)"
    else
      info "Skipping remote boot report (no ~/.config/boot-report.env found)."
      info "To enable: create that file with TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID."
      info "See: config/hypr/scripts/boot-report.sh"
    fi
  fi

  log "All done."
  cat <<EOF

Next steps (one-time):
  • Reboot to start SDDM / Hyprland and activate zram.
  • Set Brave as default browser and sign in to your apps.
  • GPU: desktop runs on the Intel iGPU (no NVIDIA driver installed by default).
  • [Optional] Enable Telegram boot reports — run once after first login:
      cp ~/erisanh/boot-report.env.example ~/.config/boot-report.env
      nano ~/.config/boot-report.env   # fill in BOT_TOKEN + CHAT_ID
      chmod 600 ~/.config/boot-report.env
    Setup guide: see boot-report.env.example

Replaced files (if any) were backed up to: $BACKUP
EOF
}

# =============================================================================
# Dispatch: pick the stage (explicit flag wins, else auto-detect)
# =============================================================================
case "${1:-auto}" in
  --bootstrap) bootstrap ;;
  --provision) provision no ;;
  --firstboot) provision yes ;;
  auto)
    if [ -d /run/archiso ]; then
      bootstrap                                   # Arch live ISO -> full reinstall
    elif command -v pacman >/dev/null 2>&1; then
      provision no                                # already-installed Arch -> provision
    else
      die "Wrong environment — this is not Arch Linux and not the Arch live ISO.

install.sh CANNOT reinstall the OS it is currently running from (e.g. your
Ubuntu). To reinstall this machine into the Arch + Hyprland setup:

  1. Download the ISO:  https://archlinux.org/download/
  2. Write it to a USB stick (>= 2 GB), e.g.:
       sudo dd if=archlinux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
  3. Reboot and boot that USB in UEFI mode.
  4. On the ISO, get online (wired = automatic; Wi-Fi: 'iwctl'), then:
       pacman -Sy --noconfirm git
       git clone https://github.com/erisanh/erisanh.git
       cd erisanh
       bash install.sh        # <- runs the disk-wipe install from here

Always use 'bash install.sh' (not 'sh') — the script needs bash."
    fi
    ;;
  *) die "Unknown option: $1  (use --bootstrap | --provision, or no argument)";;
esac
