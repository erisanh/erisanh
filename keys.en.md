# Keybindings & Common Commands

> Cheat sheet for this dotfiles workspace (Arch + Hyprland + ghostty + fish).
> Keyboard: **DAREU 75%** (has F1–F12 row; no dedicated PrtSc key).
> Notation: **SUPER** = Super/Windows key · **MEH** = `Ctrl+Shift+Alt`.
> Source of truth: `config/hypr/binds.lua`, `config/ghostty/config`, `config/tmux/tmux.conf`, `config/fish/`.

---

## 1. Hyprland — Window Manager (`config/hypr/binds.lua`)

### Apps & launcher
| Key | Action |
| --- | --- |
| `SUPER + Return` | Terminal (ghostty) |
| `SUPER + A` | App launcher (quickshell) — uses `qs ipc call launcher toggle` |
| `SUPER + Space` | **Toggle Vietnamese ⇄ English** (fcitx5 / Bamboo) |
| `SUPER + B` | Browser (zen-browser) |
| `SUPER + E` | File manager GUI (Thunar) |
| `SUPER + Y` | File manager TUI (yazi in ghostty) |
| `SUPER + D` | Discord |
| `SUPER + \` | Drop-down "quake" terminal |

### Session
| Key | Action |
| --- | --- |
| `MEH + L` | Lock screen (hyprlock) |
| `MEH + N` | Dismiss all notifications |
| `MEH + A` | Cycle animation preset (default → playful → off) |
| `SUPER + Shift + S` / `XF86PowerOff` | Power / session menu |
| `SUPER + Alt + G` | Toggle gaming mode |

### Screenshots & OCR (flameshot)
> This keyboard (DAREU 75%) has no dedicated Print/PrtSc key, so screenshots use Shift+Alt combos.

| Key | Action |
| --- | --- |
| `Shift + Alt + S` | Capture a region (select → annotate → copy/save) |
| `Shift + Alt + F` | Copy whole screen to clipboard |
| `MEH + S` | OCR a region → text to clipboard |
| `SUPER + Shift + P` | Color picker (hyprpicker) |

### Windows
| Key | Action |
| --- | --- |
| `SUPER + Q` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + M` | Maximize |
| `SUPER + T` | Toggle floating |
| `SUPER + P` | Pseudo-tile |
| `SUPER + Tab` | Previous workspace |

### Focus / Move / Resize (vim keys)
| Key | Action |
| --- | --- |
| `SUPER + H/J/K/L` | Focus left / down / up / right |
| `SUPER + Alt + H/J/K/L` | Move window |
| `SUPER + Shift + H/J/K/L` | Resize window |
| `SUPER + Alt + LMB drag` | Resize with mouse |
| `SUPER + LMB drag` | Move with mouse |

### Scrolling layout (niri-style)
| Key | Action |
| --- | --- |
| `SUPER + R` | Cycle preset column widths |
| `SUPER + - / =` | Shrink / grow column |
| `SUPER + , / .` | Move column left / right |
| `SUPER + Shift + , / .` | Swap column left / right |
| `SUPER + C` | Toggle center / fit |
| `SUPER + W` | Fit active column to screen |
| `SUPER + Shift + W` | Fit all visible columns |
| `SUPER + Ctrl + W` | Fit every column |
| `SUPER + G` | Promote column |

### Screen splitting
| Key | Action |
| --- | --- |
| `SUPER + R` | Cycle active column width (33% → 50% → 67%) |
| `SUPER + SHIFT + 2` | Arrange all windows into **2 equal columns** |
| `SUPER + SHIFT + 3` | Arrange all windows into **3 equal columns** |
| `SUPER + SHIFT + 4` | Arrange all windows into **4 equal columns** |
| `SUPER + SHIFT + 0` | Reset — fit all columns to screen |
| `SUPER + Ctrl + W` | Fit every column to screen width |

> Tip: open your windows first, then hit the split shortcut.

### Workspaces
| Key | Action |
| --- | --- |
| `SUPER + 1…9, 0` | Go to workspace 1…10 |
| `SUPER + Alt + 1…9, 0` | Move window to workspace |
| `SUPER + [ / ]` | Previous / next workspace |
| `SUPER + S` | Toggle special workspace (scratchpad) |
| `SUPER + Alt + S` | Move window to special |

### Media / volume / brightness (laptop keys)
| Key | Action |
| --- | --- |
| `XF86AudioRaiseVolume / LowerVolume / Mute` | Volume up / down / mute |
| `XF86AudioMicMute` | Mic mute |
| `XF86MonBrightnessUp / Down` | Brightness |
| `SUPER + Alt + P` | Play / pause |
| `SUPER + Alt + [ / ]` | Previous / next track |
| `XF86AudioPlay / Next / Prev` | Play-pause / next / prev (media Fn keys) |
| Power profile | Accessible via quickshell bar (no dedicated key on DAREU 75%) |

### Misc
| Key | Action |
| --- | --- |
| `SUPER + Alt + - / =` | Zoom screen out / in |
| `SUPER + Alt + V` | Toggle "VM" submap (disable keybinds; press again to exit) |
| 3-finger horizontal swipe | Switch workspace |

---

## 2. ghostty — Terminal (`config/ghostty/config`)

| Key | Action |
| --- | --- |
| `Ctrl+Shift + H/J/K/L` | Focus split left / bottom / top / right |
| `SUPER+Shift + Enter` | New split (auto) |
| `SUPER+Shift + M` | Toggle split zoom |
| `SUPER+Shift + T` | New tab |
| `SUPER+Shift + H / L` | Previous / next tab |
| `SUPER+Shift + , / .` | Move tab left / right |
| `SUPER+Shift + C / V` | Copy / paste |
| `SUPER+Shift + 0 / 9` | Font size up / down · `SUPER+Shift + +` reset |
| `SUPER+Shift + W` | Close surface |
| `SUPER+Shift + R` | Reload config |
| `SUPER+Shift + I` | Toggle inspector |

> Mouse text selection is auto-copied to the clipboard (`copy-on-select`).

---

## 3. tmux (`config/tmux/tmux.conf`) — prefix is `Ctrl+a`

| Key | Action |
| --- | --- |
| `prefix + \|` | Split horizontally (same path) |
| `prefix + -` | Split vertically (same path) |
| `prefix + c` | New window (same path) |
| `prefix + x` | Kill pane |
| `prefix + h/j/k/l` | Select pane |
| `prefix + Ctrl+h/j/k/l` | Resize pane by 1 |
| `prefix + Alt+h/j/k/l` | Resize pane by 5 |
| `prefix + Tab` | Last window |
| `prefix + T` | Project switcher popup (`tm`) |
| `v` (copy-mode) | Begin selection · `Ctrl+v` rectangle |

Shell shortcuts: `tc` attach · `ta <name>` attach to · `ts <name>` new session · `tl` list · `tk <name>` kill session · `tks` kill server.

---

## 4. fish shell shortcuts (`config/fish/`)

### Navigation & files
| Abbr | Expands to |
| --- | --- |
| `..` `...` `.3` `.4` `.5` | `cd ..`, `cd ../..`, … |
| `ls` / `la` / `ll` / `l` | `eza` (icons, dirs first) / +hidden / +long / = `ll` |
| `mkdir` | `mkdir -vp` |
| `cp` / `mv` | `cp -riv` / `mv -iv` |
| `z <dir>` / `zi` | jump with zoxide / interactive |
| `y` | yazi, then `cd` into the last directory on exit |
| `v` | nvim · `lv` LazyVim profile |

### git
| Abbr | Command |
| --- | --- |
| `g` | `git` |
| `gg` | lazygit |
| `gs` | `git st` (status) |
| `gb <name>` | `git checkout -b` |
| `gc` / `gcp` | `git commit` / `commit -p` |
| `gpp` / `gp` | `git push` / `git pull` |
| `gl` | pretty graph log |
| `gm` | checkout main (or master) |
| `gpr` | `git pr checkout` |

### docker
| Abbr | Command |
| --- | --- |
| `lad` | lazydocker |
| `d` / `dc` | `docker` / `docker compose` |
| `dcu` / `dcd` / `dcl` | compose up -d / down / logs -f |
| `dps` / `dpsa` / `di` | ps / ps -a / images |
| `dex <c>` / `dl <c>` | exec -it / logs -f |
| `drm` / `drmi` / `dprune` | rm -f / rmi / system prune -af |

### systemd & logs
| Abbr | Command |
| --- | --- |
| `s` / `su` | `systemctl` / `--user` |
| `ss <unit>` | status |
| `se` / `sd` / `sr` / `sa` / `so` | enable / disable / restart / start / stop (`--now`) |
| `sl` / `slu` | running services (system / user) |
| `sf` | failed units |
| `jb` / `jf` / `jg <re>` | journal: boot / follow / grep |
| `ju <unit>` / `juu <unit>` | follow a unit / user-unit |

---

## 5. Common command recipes

### Install / manage apps (yay + pacman)
```bash
yay -S <pkg>            # install (AUR + repo). `yay` alias = `yay --sudoloop`
sudo pacman -S <pkg>    # install from official repos only
yay -Ss <term>          # search
yay -Rns <pkg>          # remove app + unused deps + config
yay -Syu                # update everything (system + AUR)
pacman -Qq              # list installed packages
pkgInfo                 # fuzzy package browser (fzf + bat preview)
clean                   # clear pacman/yay caches + show disk usage
```

### Extract / compress archives
```bash
# zip
unzip file.zip                  # extract
unzip file.zip -d out/          # extract into out/
zip -r archive.zip folder/      # compress a folder

# tar (.tar.gz / .tgz / .tar.xz / .tar.bz2)
tar -xf archive.tar.gz          # extract (auto-detects compression)
tar -xf archive.tar.gz -C out/  # extract into out/
tar -czf archive.tar.gz folder/ # compress with gzip
tar -cJf archive.tar.xz folder/ # compress with xz (smaller)

# 7z (p7zip) — handles zip/7z/rar-read and more
7z x archive.7z                 # extract (keep paths)
7z a archive.7z folder/         # compress

# Or just open the archive in yazi (SUPER+Y) and browse/extract.
```

### Find & search
```bash
fd <name>          # find files (fast). `fda` = include hidden + ignored
rg <pattern>       # search file contents. `rga` = search everything
fzf                # fuzzy picker;  Ctrl+R = shell history (atuin)
bat <file>         # view file with syntax highlighting
duf                # disk usage by mount; ncdu = interactive
```

### git / docker / services
```bash
gg                 # lazygit TUI;  gs / gc / gpp / gp for quick git
lad                # lazydocker TUI
dcu / dcd / dcl    # docker compose up -d / down / logs
se <unit>          # enable + start a service now
ss <unit>          # service status
```

### System & misc
```bash
fast <cmd>         # run a command in the "performance" power profile
weather            # current weather (Hanoi)
hyprctl reload     # reload Hyprland config after editing
~/.config/hypr/scripts/anim-preset.sh playful   # switch animations (or MEH+A)
cava               # audio visualizer in the terminal
```
