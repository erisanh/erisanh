# Phím tắt — illogical-impulse (end-4/dots-hyprland)

> Máy này chạy bộ **illogical-impulse** cho Hyprland (Quickshell + Material 3).
> Cài qua `~/dots-hyprland/setup install`. Đây là phím mặc định của bản gốc —
> xem danh sách đầy đủ trong hệ thống bất cứ lúc nào bằng **Super + /**.

## Cơ bản
| Phím | Hành động |
| --- | --- |
| `Super + /` | Hiện bảng phím tắt đầy đủ |
| `Super + Enter` | Mở terminal |
| `Super + T` | Mở terminal (thay thế) |
| `Super + E` | Trình quản lý file |
| `Super + W` | Trình duyệt |
| `Super + C` | Trình soạn code |
| `Super` (nhấn nhả) | Overview / tìm ứng dụng |
| `Super + Tab` | Overview |
| `Super + Q` | Đóng cửa sổ hiện tại |
| `Ctrl + Alt + Delete` | Menu phiên (đăng xuất/khởi động lại/tắt) |

## Quản lý cửa sổ
| Phím | Hành động |
| --- | --- |
| `Super + ←/→/↑/↓` | Chuyển focus |
| `Super + Shift + ←/→/↑/↓` | Di chuyển cửa sổ |
| `Super + 1..0` | Sang workspace 1–10 |
| `Super + Shift + 1..0` | Đưa cửa sổ sang workspace 1–10 |
| `Super + S` | Bật/tắt workspace đặc biệt (scratchpad) |
| `Super + F` | Toàn màn hình |
| `Super + Alt + Space` | Bật/tắt chế độ nổi (floating) |
| `Super + Scroll` | Chuyển workspace |

## Tiện ích (illogical-impulse)
| Phím | Hành động |
| --- | --- |
| `Super + V` | Lịch sử clipboard |
| `Super + .` | Bảng chọn emoji |
| `Super + Shift + S` | Chụp vùng màn hình |
| `Print` | Chụp toàn màn hình |
| `Super + Shift + T` | Dịch màn hình (OCR) |
| `Super + Shift + C` | Bút lấy màu |
| `Super + K` | Bật/tắt bàn phím ảo |
| `Super + L` | Khóa màn hình |

## Sidebar & widget
| Phím | Hành động |
| --- | --- |
| `Super + A` | Sidebar trái (AI / công cụ) |
| `Super + N` | Sidebar phải (thông báo, lịch) |
| `Super + M` | Điều khiển nhạc / media |
| `Super + B` | Bật/tắt thanh bar |

## Gõ tiếng Việt (thêm vào ngoài illogical-impulse)
| Phím | Hành động |
| --- | --- |
| `Ctrl + Space` | Chuyển bộ gõ fcitx5 (US ↔ Bamboo) |
| `Super + Space` | Đổi layout bàn phím (Hyprland) |

> Gõ tiếng Việt dùng **fcitx5 + bamboo**. Cấu hình bằng `fcitx5-configtool`.

## Script giữ lại từ bộ cũ
| Lệnh | Hành động |
| --- | --- |
| `~/.local/bin/boot-report.sh --boot` | Gửi báo cáo boot/lỗi về Telegram |
| `~/.local/bin/activity-logger.sh` | Gửi log hoạt động về Telegram |
