# Chrome Remote Desktop on Arch Linux (Hyprland)

Set up Chrome Remote Desktop (CRD) so another machine (e.g. work PC) can remote
into this Arch box — for example while you're at the office.

## Key facts

- **Do NOT use the `.deb`** (`chrome-remote-desktop_current_amd64.deb`) — that's
  a Debian/Ubuntu package. On Arch, install from the **AUR** via `yay` so it's
  managed by pacman. The `.deb` can be deleted.
- **CRD does not support Wayland.** This machine runs Hyprland (Wayland), so CRD
  runs a **separate headless Xfce (X11) session** — a "second computer" sharing
  the same hardware. Windows open in your real Hyprland desktop are NOT visible
  in the remote session, and vice versa.
- The virtual Xfce session is a **persistent background daemon**: disconnecting
  leaves apps/windows exactly where they were, so reconnecting later shows the
  same state. No desktop re-login needed.
- **Resource use:** idle ≈ 200–400 MB RAM, ~0% CPU. CPU only rises (~10–30% of a
  few cores) while someone is actively connected. Running alongside Hyprland is
  effectively free when idle.
- **The machine must stay ON with network** to be reachable. Sleep/suspend
  drops the connection (NIC powers off; Wake-on-LAN only works on the same LAN).
  Auto-suspend on idle is therefore disabled — but **manual sleep/shutdown still
  works normally** when you're sitting at the machine.

## Already done (no sudo needed)

- ✅ Created `~/.chrome-remote-desktop-session` (launches Xfce for the headless
  session).
- ✅ Disabled the 15-min idle auto-suspend in `~/.config/hypr/hypridle.conf`
  (kept screen-lock at 5 min and DPMS screen-off at 10 min — both harmless).
  To restore auto-suspend, un-comment the `listener` block with `$suspend`.
- ✅ Installed `chrome-remote-desktop` (AUR) + `xfce4` via `yay`. The AUR package
  auto-downloads Google's current build, created the `chrome-remote-desktop`
  system group, and provides `crd` / `start-host`.

## Remaining steps (run in a real terminal — these are interactive)

```bash
# 1. Add your user to the CRD group
sudo gpasswd -a iubeha chrome-remote-desktop

# 2. Reboot so the new group membership takes effect
systemctl reboot

# 3. Authorize with Google (do this right after reboot — the code expires in minutes)
#    a) On any browser: https://remotedesktop.google.com/headless
#    b) Sign in → Begin → Next → Authorize.
#    c) Google shows a long Debian-style command. Copy ONLY the --code="..." part
#       and run this on the Arch machine (rename via --name as you like):
DISPLAY= /opt/google/chrome-remote-desktop/start-host \
  --code="PASTE_CODE_HERE" \
  --redirect-url="https://remotedesktop.google.com/_/oauthredirect" \
  --name=archhome
#    d) It asks for a 6-digit PIN (entered twice) — used to connect later.

# 4. Auto-start CRD on every boot (important for the work-from-office scenario)
sudo systemctl enable chrome-remote-desktop@iubeha

# 5. Verify the host service is running
systemctl status chrome-remote-desktop@iubeha
```

## Connect from the other machine

Open <https://remotedesktop.google.com/access>, sign in with the **same Google
account**, pick **archhome**, enter the **PIN** → you're in the Xfce session.

## Notes

- Don't copy Google's command verbatim — it calls `$(hostname)`, and this box
  lacks the `hostname` binary; that's why `--name=archhome` is set explicitly.
- The headless session needs no monitor — screen off / locked is fine.
- Before leaving for work: make sure the machine stays **on** and **online**
  (don't suspend/shutdown). If it's asleep, no remote solution can wake it from
  a different network.
