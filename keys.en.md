# Keybindings — illogical-impulse (end-4/dots-hyprland)

> This machine runs the **illogical-impulse** Hyprland setup (Quickshell + Material 3).
> Installed via `~/dots-hyprland/setup install`. These are the upstream defaults —
> see the in-system list any time with **Super + /**.

## Essentials
| Key | Action |
| --- | --- |
| `Super + /` | Show the full keybind cheat sheet |
| `Super + Enter` | Open terminal |
| `Super + T` | Open terminal (alt) |
| `Super + E` | File manager |
| `Super + W` | Browser |
| `Super + C` | Code editor |
| `Super` (tap) | Overview / app search |
| `Super + Tab` | Overview |
| `Super + Q` | Close active window |
| `Ctrl + Alt + Delete` | Session menu (logout/reboot/shutdown) |

## Window management
| Key | Action |
| --- | --- |
| `Super + ←/→/↑/↓` | Move focus |
| `Super + Shift + ←/→/↑/↓` | Move window |
| `Super + 1..0` | Go to workspace 1–10 |
| `Super + Shift + 1..0` | Move window to workspace 1–10 |
| `Super + S` | Toggle special workspace (scratchpad) |
| `Super + F` | Fullscreen |
| `Super + Alt + Space` | Toggle floating |
| `Super + Scroll` | Switch workspace |

## Quality of life (illogical-impulse)
| Key | Action |
| --- | --- |
| `Super + V` | Clipboard history |
| `Super + .` | Emoji picker |
| `Super + Shift + S` | Region screenshot |
| `Print` | Full screenshot |
| `Super + Shift + T` | Screen translation (OCR) |
| `Super + Shift + C` | Color picker |
| `Super + K` | On-screen keyboard toggle |
| `Super + L` | Lock screen |

## Sidebars & widgets
| Key | Action |
| --- | --- |
| `Super + A` | Left sidebar (AI / tools) |
| `Super + N` | Right sidebar (notifications, calendar) |
| `Super + M` | Music / media controls |
| `Super + B` | Toggle bar |

## Vietnamese input (added on top of illogical-impulse)
| Key | Action |
| --- | --- |
| `Ctrl + Space` | Toggle fcitx5 input method (US ↔ Bamboo) |
| `Super + Space` | Switch keyboard layout (Hyprland) |

> Vietnamese typing uses **fcitx5 + bamboo**. Configure with `fcitx5-configtool`.

## App shortcuts (added via setup-app.sh)
| Key | Action |
| --- | --- |
| `Super + Alt + B` | Bruno (API client) |
| `Super + Alt + C` | Visual Studio Code |
| `Super + Alt + D` | Figma (figma-linux) |
| `Super + Alt + E` | Microsoft Teams |
| `Super + Alt + J` | JetBrains Toolbox *(written when installed)* |
| `Super + Alt + T` | Telegram |
| `Super + Alt + V` | CapCut (web app via Brave) |
| `Super + Alt + Z` | Zalo |

> Managed block in `~/.config/hypr/custom/keybinds.lua`. Re-run
> `bash ~/erisanh/setup-app.sh shortcuts` to sync after installing new apps.

## Helpers kept from the previous setup
| Command | Action |
| --- | --- |
| `~/.local/bin/boot-report.sh --boot` | Send boot/error report to Telegram |
| `~/.local/bin/activity-logger.sh` | Stream activity events to Telegram |
