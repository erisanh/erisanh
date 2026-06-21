# Phím tắt & Lệnh hay dùng

> Bảng tra nhanh cho workspace dotfiles này (Arch + Hyprland + ghostty + fish).
> Ký hiệu: **SUPER** = phím Super/Windows · **MEH** = `Ctrl+Shift+Alt`.
> Nguồn gốc: `config/hypr/binds.lua`, `config/ghostty/config`, `config/tmux/tmux.conf`, `config/fish/`.

---

## 1. Hyprland — Quản lý cửa sổ (`config/hypr/binds.lua`)

### Ứng dụng & launcher
| Phím | Hành động |
| --- | --- |
| `SUPER + Return` | Terminal (ghostty) |
| `SUPER + Space` | Trình mở ứng dụng (quickshell launcher) |
| `SUPER + B` | Trình duyệt (zen-browser) |
| `SUPER + E` | File manager GUI (Dolphin) |
| `SUPER + Y` | File manager TUI (yazi trong ghostty) |
| `SUPER + D` | Discord |
| `SUPER + \` | Terminal "quake" thả xuống |

### Phiên làm việc
| Phím | Hành động |
| --- | --- |
| `MEH + L` | Khóa màn hình (hyprlock) |
| `MEH + N` | Xóa hết thông báo |
| `MEH + A` | Đổi preset animation (default → playful → off) |
| `SUPER + Shift + S` / `XF86PowerOff` | Menu nguồn / phiên |
| `SUPER + F1` | Bật/tắt gaming mode |

### Chụp màn hình & OCR
| Phím | Hành động |
| --- | --- |
| `Print` | Chụp vùng → clipboard (đóng băng màn hình) |
| `Shift + Print` | Chụp vùng → lưu file |
| `SUPER + Print` | Chụp toàn màn hình → clipboard |
| `SUPER + Shift + Print` | Chụp toàn màn hình → lưu file |
| `MEH + S` | OCR một vùng → chữ vào clipboard |
| `SUPER + Shift + P` | Lấy mã màu (hyprpicker) |

### Cửa sổ
| Phím | Hành động |
| --- | --- |
| `SUPER + Q` | Đóng cửa sổ |
| `SUPER + F` | Toàn màn hình |
| `SUPER + M` | Phóng to (maximize) |
| `SUPER + T` | Bật/tắt nổi (floating) |
| `SUPER + P` | Pseudo-tile |
| `SUPER + Tab` | Workspace trước đó |

### Focus / Di chuyển / Resize (phím vim)
| Phím | Hành động |
| --- | --- |
| `SUPER + H/J/K/L` | Focus trái / xuống / lên / phải |
| `SUPER + Alt + H/J/K/L` | Di chuyển cửa sổ |
| `SUPER + Shift + H/J/K/L` | Resize cửa sổ |
| `SUPER + Kéo chuột trái` | Di chuyển bằng chuột |
| `SUPER + Alt + Kéo chuột trái` | Resize bằng chuột |

### Layout cuộn (kiểu niri)
| Phím | Hành động |
| --- | --- |
| `SUPER + R` | Đổi vòng các độ rộng cột định sẵn |
| `SUPER + - / =` | Thu nhỏ / phóng to cột |
| `SUPER + , / .` | Dời cột trái / phải |
| `SUPER + Shift + , / .` | Hoán đổi cột trái / phải |
| `SUPER + C` | Bật/tắt căn giữa / fit |
| `SUPER + W` | Vừa cột đang focus với màn hình |
| `SUPER + Shift + W` | Vừa tất cả cột đang hiện |
| `SUPER + Ctrl + W` | Vừa mọi cột |
| `SUPER + G` | Promote (đưa cột lên chính) |

### Workspace
| Phím | Hành động |
| --- | --- |
| `SUPER + 1…9, 0` | Sang workspace 1…10 |
| `SUPER + Alt + 1…9, 0` | Chuyển cửa sổ sang workspace |
| `SUPER + [ / ]` | Workspace trước / sau |
| `SUPER + S` | Bật/tắt special workspace (scratchpad) |
| `SUPER + Alt + S` | Đưa cửa sổ vào special |

### Media / âm lượng / độ sáng (phím laptop)
| Phím | Hành động |
| --- | --- |
| `XF86AudioRaiseVolume / LowerVolume / Mute` | Tăng / giảm / tắt tiếng |
| `XF86AudioMicMute` | Tắt mic |
| `XF86MonBrightnessUp / Down` | Độ sáng |
| `SUPER + Alt + P` | Phát / tạm dừng nhạc |
| `SUPER + Alt + [ / ]` | Bài trước / bài sau |
| `XF86Launch4` | Đổi vòng hồ sơ điện năng |

### Khác
| Phím | Hành động |
| --- | --- |
| `SUPER + Alt + - / =` | Thu / phóng (zoom) màn hình |
| `SUPER + Alt + F1` | Bật/tắt submap "VM" (tắt phím tắt; bấm lại để thoát) |
| Vuốt 3 ngón ngang | Đổi workspace |

---

## 2. ghostty — Terminal (`config/ghostty/config`)

| Phím | Hành động |
| --- | --- |
| `Ctrl+Shift + H/J/K/L` | Focus split trái / dưới / trên / phải |
| `SUPER+Shift + Enter` | Tách ô mới (auto) |
| `SUPER+Shift + M` | Phóng to ô đang focus |
| `SUPER+Shift + T` | Tab mới |
| `SUPER+Shift + H / L` | Tab trước / sau |
| `SUPER+Shift + , / .` | Dời tab trái / phải |
| `SUPER+Shift + C / V` | Copy / paste |
| `SUPER+Shift + 0 / 9` | Cỡ chữ to / nhỏ · `SUPER+Shift + +` reset |
| `SUPER+Shift + W` | Đóng ô |
| `SUPER+Shift + R` | Nạp lại config |
| `SUPER+Shift + I` | Bật/tắt inspector |

> Bôi đen chuột tự copy vào clipboard (`copy-on-select`).

---

## 3. tmux (`config/tmux/tmux.conf`) — prefix là `Ctrl+a`

| Phím | Hành động |
| --- | --- |
| `prefix + \|` | Tách ngang (giữ thư mục) |
| `prefix + -` | Tách dọc (giữ thư mục) |
| `prefix + c` | Cửa sổ mới (giữ thư mục) |
| `prefix + x` | Đóng pane |
| `prefix + h/j/k/l` | Chọn pane |
| `prefix + Ctrl+h/j/k/l` | Resize pane 1 ô |
| `prefix + Alt+h/j/k/l` | Resize pane 5 ô |
| `prefix + Tab` | Cửa sổ vừa rồi |
| `prefix + T` | Popup chuyển dự án (`tm`) |
| `v` (copy-mode) | Bắt đầu bôi đen · `Ctrl+v` chọn khối |

Phím tắt shell: `tc` attach · `ta <tên>` attach vào · `ts <tên>` session mới · `tl` liệt kê · `tk <tên>` kill session · `tks` kill server.

---

## 4. Phím tắt fish shell (`config/fish/`)

### Điều hướng & file
| Viết tắt | Mở rộng thành |
| --- | --- |
| `..` `...` `.3` `.4` `.5` | `cd ..`, `cd ../..`, … |
| `ls` / `la` / `ll` / `l` | `eza` (icon, thư mục trước) / +ẩn / +chi tiết / = `ll` |
| `mkdir` | `mkdir -vp` |
| `cp` / `mv` | `cp -riv` / `mv -iv` |
| `z <dir>` / `zi` | nhảy nhanh bằng zoxide / chọn tương tác |
| `y` | yazi, thoát ra thì `cd` vào thư mục cuối |
| `v` | nvim · `lv` profile LazyVim |

### git
| Viết tắt | Lệnh |
| --- | --- |
| `g` | `git` |
| `gg` | lazygit |
| `gs` | `git st` (trạng thái) |
| `gb <tên>` | `git checkout -b` |
| `gc` / `gcp` | `git commit` / `commit -p` |
| `gpp` / `gp` | `git push` / `git pull` |
| `gl` | log đồ thị đẹp |
| `gm` | checkout main (hoặc master) |
| `gpr` | `git pr checkout` |

### docker
| Viết tắt | Lệnh |
| --- | --- |
| `lad` | lazydocker |
| `d` / `dc` | `docker` / `docker compose` |
| `dcu` / `dcd` / `dcl` | compose up -d / down / logs -f |
| `dps` / `dpsa` / `di` | ps / ps -a / images |
| `dex <c>` / `dl <c>` | exec -it / logs -f |
| `drm` / `drmi` / `dprune` | rm -f / rmi / system prune -af |

### systemd & log
| Viết tắt | Lệnh |
| --- | --- |
| `s` / `su` | `systemctl` / `--user` |
| `ss <unit>` | trạng thái |
| `se` / `sd` / `sr` / `sa` / `so` | enable / disable / restart / start / stop (`--now`) |
| `sl` / `slu` | service đang chạy (hệ thống / user) |
| `sf` | unit lỗi |
| `jb` / `jf` / `jg <re>` | journal: boot / theo dõi / tìm |
| `ju <unit>` / `juu <unit>` | theo dõi 1 unit / user-unit |

---

## 5. Công thức lệnh hay dùng

### Cài / quản lý app (yay + pacman)
```bash
yay -S <pkg>            # cài app (AUR + repo). alias `yay` = `yay --sudoloop`
sudo pacman -S <pkg>    # chỉ cài từ repo chính thức
yay -Ss <từ_khóa>       # tìm gói
yay -Rns <pkg>          # gỡ app + deps thừa + config
yay -Syu                # cập nhật tất cả (hệ thống + AUR)
pacman -Qq              # liệt kê gói đã cài
pkgInfo                 # duyệt gói bằng fzf (xem trước bằng bat)
clean                   # dọn cache pacman/yay + xem dung lượng đĩa
```

### Giải nén / nén file
```bash
# zip
unzip file.zip                  # giải nén
unzip file.zip -d out/          # giải nén vào thư mục out/
zip -r archive.zip folder/      # nén một thư mục

# tar (.tar.gz / .tgz / .tar.xz / .tar.bz2)
tar -xf archive.tar.gz          # giải nén (tự nhận loại nén)
tar -xf archive.tar.gz -C out/  # giải nén vào out/
tar -czf archive.tar.gz folder/ # nén bằng gzip
tar -cJf archive.tar.xz folder/ # nén bằng xz (nhỏ hơn)

# 7z (p7zip) — đọc/ghi zip/7z, đọc được rar...
7z x archive.7z                 # giải nén (giữ cấu trúc thư mục)
7z a archive.7z folder/         # nén

# Hoặc mở thẳng file nén trong yazi (SUPER+Y) để xem/giải nén.
```

### Tìm & search
```bash
fd <tên>           # tìm file (nhanh). `fda` = kèm file ẩn + bị ignore
rg <mẫu>           # tìm trong nội dung file. `rga` = tìm mọi thứ
fzf                # bộ chọn fuzzy;  Ctrl+R = lịch sử lệnh (atuin)
bat <file>         # xem file có tô màu cú pháp
duf                # dung lượng theo ổ; ncdu = duyệt tương tác
```

### git / docker / service
```bash
gg                 # lazygit (TUI);  gs / gc / gpp / gp cho thao tác nhanh
lad                # lazydocker (TUI)
dcu / dcd / dcl    # docker compose up -d / down / logs
se <unit>          # bật + chạy 1 service ngay
ss <unit>          # trạng thái service
```

### Hệ thống & khác
```bash
fast <lệnh>        # chạy lệnh ở hồ sơ điện năng "performance"
weather            # thời tiết hiện tại (Hà Nội)
hyprctl reload     # nạp lại config Hyprland sau khi sửa
~/.config/hypr/scripts/anim-preset.sh playful   # đổi animation (hoặc MEH+A)
cava               # trình hiển thị nhạc (visualizer) trong terminal
```
