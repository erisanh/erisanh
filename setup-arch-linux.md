---

### Lưu ý trước khi bắt đầu
1. **Sao lưu dữ liệu quan trọng**:
   - Việc cài đặt Arch Linux sẽ **xóa toàn bộ dữ liệu** trên ổ đĩa được chọn, bao gồm Windows 11 và tất cả tệp cá nhân. Hãy sao lưu mọi dữ liệu quan trọng (tài liệu, ảnh, video, v.v.) vào ổ cứng ngoài, USB, hoặc dịch vụ đám mây (Google Drive, OneDrive, v.v.).
   - Nếu bạn sử dụng BitLocker trên Windows 11, hãy kiểm tra và lưu **Recovery Key** của BitLocker (xem chi tiết bên dưới).

2. **BitLocker và Recovery Key của Microsoft**:
   - Nếu ổ đĩa Windows 11 của bạn được mã hóa bằng **BitLocker** (thường gặp trên các máy tính Windows hiện đại, đặc biệt là laptop), bạn cần **Recovery Key** để truy cập hoặc tắt BitLocker trước khi xóa Windows.
   - **Cách kiểm tra và lấy Recovery Key**:
     - Mở **Settings** trên Windows 11 (`Win + I`) > **System** > **Storage** > **Advanced storage settings** > **Disks & volumes**. Kiểm tra xem ổ đĩa hệ thống có ghi “BitLocker encrypted” không.
     - Nếu BitLocker đang bật, tìm Recovery Key trong:
       - Tài khoản Microsoft của bạn: Truy cập https://account.microsoft.com/devices/recoverykey (đăng nhập bằng tài khoản Microsoft liên kết với máy tính).
       - In hoặc lưu trong USB: Nếu bạn đã in hoặc lưu key trước đó.
       - Trong Azure Active Directory (nếu dùng tài khoản công ty).
     - **Tắt BitLocker** (khuyến nghị để tránh lỗi khi cài Arch Linux):
       - Mở **Control Panel** > **System and Security** > **BitLocker Drive Encryption**.
       - Chọn ổ đĩa hệ thống, nhấn **Turn off BitLocker**, và chờ giải mã (có thể mất thời gian tùy dung lượng ổ).
       - Nếu không tắt BitLocker, bạn cần cung cấp Recovery Key khi truy cập ổ đĩa trong quá trình cài đặt Arch Linux.

3. **Yêu cầu phần cứng**:
   - Arch Linux nhẹ và linh hoạt, nhưng bạn cần đảm bảo máy tính có ít nhất:
     - RAM: 512 MB (khuyến nghị 2 GB trở lên).
     - Dung lượng ổ đĩa: Tối thiểu 2 GB (khuyến nghị 20 GB+ để cài thêm phần mềm).
     - CPU: Hỗ trợ 64-bit (x86_64).
     - Kết nối Internet: Cần thiết để tải gói cài đặt (Ethernet hoặc Wi-Fi).

4. **Chuẩn bị công cụ**:
   - **USB (tối thiểu 4 GB)**: Để tạo USB boot cài đặt Arch Linux.
   - **File ISO Arch Linux**: Tải từ trang chính thức https://archlinux.org/download/.
   - **Phần mềm tạo USB boot**: Sử dụng **Rufus** (trên Windows) hoặc **Etcher**.
   - **Máy tính có kết nối Internet**: Để tải gói cài đặt và cấu hình hệ thống.

5. **Cảnh báo**:
   - Arch Linux không có giao diện đồ họa (GUI) mặc định, yêu cầu bạn sử dụng dòng lệnh (command-line) để cài đặt. Nếu bạn chưa quen với Linux hoặc dòng lệnh, hãy cân nhắc dùng các bản phân phối thân thiện hơn như Ubuntu hoặc Linux Mint trước khi thử Arch Linux.�[](https://thuanbui.me/cai-dat-arch-linux-hyper-v/)[](https://vinahost.vn/arch-linux-la-gi/)
   - Quá trình cài đặt sẽ xóa sạch Windows 11, vì vậy không thể quay lại Windows trừ khi bạn cài lại từ đầu.

---

### Hướng dẫn cài đặt Arch Linux thay thế Windows 11

#### Bước 1: Tải và tạo USB boot Arch Linux
1. **Tải file ISO Arch Linux**:
   - Truy cập https://archlinux.org/download/ và tải file ISO mới nhất (ví dụ: `archlinux-2025.07.01-x86_64.iso`).
   - Kiểm tra tính toàn vẹn của file ISO bằng cách so sánh mã SHA256 hoặc GPG signature (hướng dẫn trên trang tải).

2. **Tạo USB boot**:
   - Cắm USB (tối thiểu 4 GB) vào máy tính Windows 11.
   - Tải và cài đặt **Rufus** từ https://rufus.ie/.
   - Mở Rufus:
     - Chọn USB trong mục **Device**.
     - Chọn file ISO Arch Linux trong mục **Boot selection**.
     - Đảm bảo định dạng là **FAT32** hoặc **exFAT** (cho UEFI).
     - Nhấn **Start** và chờ Rufus ghi file ISO vào USB.
   - Sau khi hoàn tất, USB sẽ trở thành USB boot Arch Linux.

3. **Kiểm tra chế độ boot của máy**:
   - Xác định máy tính của bạn sử dụng **UEFI** hay **Legacy (BIOS)**:
     - Vào **Settings** > **System** > **About** > Kiểm tra **BIOS Mode** trong **Device specifications** (nếu là UEFI, bạn cần cấu hình UEFI; nếu là Legacy, cần cấu hình khác).
   - Tắt **Secure Boot** trong BIOS/UEFI (nếu cần):
     - Khởi động lại máy, nhấn phím vào BIOS (thường là `F2`, `Del`, `F12`, hoặc `Esc`).
     - Tìm mục **Secure Boot** trong tab **Boot** hoặc **Security** và tắt nó.
     - Lưu thay đổi và thoát (thường bằng phím `F10`).

#### Bước 2: Khởi động từ USB và chuẩn bị hệ thống
1. **Khởi động từ USB**:
   - Cắm USB boot vào máy tính, khởi động lại.
   - Vào menu boot (nhấn phím như `F12`, `F10`, hoặc `Esc` tùy máy).
   - chọn USB trong danh sách thiết bị khởi động.
   - Khi Arch Linux live USB khởi động, bạn sẽ thấy giao diện dòng lệnh. Chọn **Arch Linux arch install** và nhấn Enter.

2. **Kiểm tra kết nối Internet**:
   - Nếu dùng Ethernet, kết nối thường tự động.
   - Nếu dùng Wi-Fi:
     ```bash
     iwctl
     device list
     station wlan0 scan
     station wlan0 get-networks
     station wlan0 connect "SSID"
     ```
     Thay `SSID` bằng tên Wi-Fi của bạn, sau đó nhập mật khẩu khi được yêu cầu.
   - Kiểm tra kết nối:
     ```bash
     ping archlinux.org
     ```
     Nếu thấy phản hồi, bạn đã kết nối Internet.

3. **Cập nhật đồng hồ hệ thống**:
   ```bash
   timedatectl set-ntp true
   ```

#### Bước 3: Chia phân vùng ổ đĩa
Vì bạn muốn thay thế Windows 11, bạn cần xóa toàn bộ phân vùng hiện tại và tạo phân vùng mới cho Arch Linux.

1. **Kiểm tra ổ đĩa**:
   ```bash
   lsblk
   ```
   Xác định ổ đĩa chính (thường là `/dev/sda` hoặc `/dev/nvme0n1`).

2. **Chia phân vùng bằng `fdisk`**:
   ```bash
   fdisk /dev/sda
   ```
   - Nhấn `d` để xóa tất cả phân vùng hiện tại (bao gồm phân vùng Windows 11).
   - Tạo phân vùng mới:
     - Nhấn `n` để tạo phân vùng mới, chọn `primary` và gán dung lượng:
       - **EFI System Partition** (cho UEFI): 512 MB, loại `efi` (`ef00`).
       - **Swap**: 4 GB (hoặc bằng/gấp đôi RAM), loại `linux swap` (`8200`).
       - **Root**: Phần còn lại của ổ đĩa, loại `linux filesystem` (`8300`).
     - Nhấn `w` để lưu và thoát.
   - Ví dụ cấu trúc phân vùng:
     ```
     /dev/sda1: 512 MB (EFI)
     /dev/sda2: 4 GB (Swap)
     /dev/sda3: Còn lại (Root)
     ```

3. **Định dạng phân vùng**:
   ```bash
   mkfs.fat -F32 /dev/sda1  # EFI
   mkswap /dev/sda2          # Swap
   mkfs.ext4 /dev/sda3       # Root
   swapon /dev/sda2          # Kích hoạt Swap
   ```

4. **Gắn kết phân vùng**:
   ```bash
   mount /dev/sda3 /mnt
   mkdir /mnt/boot
   mount /dev/sda1 /mnt/boot
   ```

#### Bước 4: Cài đặt hệ thống cơ bản
1. **Cài đặt các gói cơ bản**:
   ```bash
   pacstrap /mnt base linux linux-firmware
   ```

2. **Tạo file hệ thống fstab**:
   ```bash
   genfstab -U /mnt >> /mnt/etc/fstab
   ```

#### Bước 5: Cấu hình hệ thống
1. **Chuyển vào hệ thống mới**:
   ```bash
   arch-chroot /mnt
   ```

2. **Cài đặt múi giờ**:
   - Ví dụ, cho Việt Nam (Asia/Ho_Chi_Minh):
     ```bash
     ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
     hwclock --systohc
     ```

3. **Cấu hình ngôn ngữ**:
   - Chỉnh sửa `/etc/locale.gen`:
     ```bash
     nano /etc/locale.gen
     ```
     - Bỏ dấu `#` trước dòng `en_US.UTF-8 UTF-8` hoặc `vi_VN.UTF-8 UTF-8` (nếu có).
     - Lưu và thoát (`Ctrl + X`, `Y`, Enter).
   - Tạo locale:
     ```bash
     locale-gen
     echo "LANG=en_US.UTF-8" > /etc/locale.conf
     ```

4. **Cấu hình hostname**:
   ```bash
   echo "myhostname" > /etc/hostname
   ```
   Thay `myhostname` bằng tên máy tính bạn muốn.

5. **Cấu hình mạng**:
   ```bash
   pacman -S networkmanager
   systemctl enable NetworkManager
   ```

6. **Đặt mật khẩu root**:
   ```bash
   passwd
   ```
   Nhập và xác nhận mật khẩu root.

7. **Tạo người dùng mới**:
   ```bash
   useradd -m -G wheel username
   passwd username
   ```
   Thay `username` bằng tên người dùng bạn muốn.
   - Cấp quyền sudo:
     ```bash
     pacman -S sudo
     EDITOR=nano visudo
     ```
     - Bỏ dấu `#` trước dòng `% russe wheel ALL=(ALL) ALL`.
     - Lưu và thoát.

#### Bước 6: Cài đặt Bootloader (GRUB)
1. **Cài đặt GRUB**:
   ```bash
   pacman -S grub efibootmgr
   grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
   ```

2. **Thoát và khởi động lại**:
   ```bash
   exit
   umount -R /mnt
   reboot
   ```
   - Rút USB boot ra trước khi khởi động lại.

#### Bước 7: Hoàn thiện cài đặt
- Sau khi khởi động lại, bạn sẽ vào Arch Linux với giao diện dòng lệnh.
- Để cài giao diện đồ họa (nếu muốn):
  - Cài môi trường desktop (ví dụ: GNOME):
    ```bash
    pacman -S gnome
    systemctl enable gdm
    ```
  - Hoặc XFCE, KDE Plasma, tùy sở thích.
  - Khởi động lại:
    ```bash
    reboot
    ```

---

### Các lưu ý quan trọng
1. **Về Recovery Key của Microsoft**:
   - Nếu bạn không tắt BitLocker trước khi cài Arch Linux, bạn có thể gặp lỗi khi truy cập ổ đĩa. Đảm bảo đã lưu Recovery Key hoặc tắt BitLocker hoàn toàn.[](https://support.microsoft.com/vi-vn/topic/c%25C3%25A1ch-g%25E1%25BB%25A1-b%25E1%25BB%258F-linux-v%25C3%25A0-c%25C3%25A0i-%25C4%2591%25E1%25BA%25B7t-windows-tr%25C3%25AAn-m%25C3%25A1y-t%25C3%25ADnh-c%25E1%25BB%25A7a-b%25E1%25BA%25A1n-f489c550-f8ec-b458-0a64-c3a8d60d3497)
   - Sau khi cài Arch Linux, Windows 11 sẽ bị xóa hoàn toàn, và bạn không cần Recovery Key nữa trừ khi bạn muốn cài lại Windows sau này.
   - Nếu bạn cần cài lại Windows 11 trong tương lai, hãy lưu ý:
     - Tải file ISO Windows 11 từ https://www.microsoft.com/software-download/windows11.
     - Chuẩn bị USB boot và key bản quyền Windows (nếu có). Key bản quyền có thể được liên kết với tài khoản Microsoft hoặc phần cứng máy tính (OEM license).

2. **Các vấn đề thường gặp**:
   - **Không kết nối Wi-Fi**: Kiểm tra driver Wi-Fi bằng `lspci` hoặc `lsusb`, sau đó cài driver cần thiết (ví dụ: `broadcom-wl` cho card Broadcom).
   - **GRUB không khởi động**: Kiểm tra lại cấu hình UEFI trong BIOS và đảm bảo đã cài `efibootmgr`.
   - **Không có giao diện đồ họa**: Bạn cần cài đặt môi trường desktop (như GNOME, KDE) sau khi cài hệ thống cơ bản.

3. **Tài liệu tham khảo**:
   - Xem thêm hướng dẫn chính thức từ Arch Wiki: https://wiki.archlinux.org/title/Installation_guide.
   - Nếu gặp lỗi, tra cứu trên Arch Wiki hoặc diễn đàn Arch Linux.

4. **Hỗ trợ sau cài đặt**:
   - Arch Linux yêu cầu cấu hình thủ công nhiều hơn các bản phân phối khác. Nếu bạn mới dùng Linux, hãy dành thời gian tìm hiểu về `pacman` (trình quản lý gói) và các lệnh cơ bản.
   - Tham gia cộng đồng Arch Linux trên Reddit (`r/archlinux`) hoặc diễn đàn chính thức để được hỗ trợ.

---

Nếu bạn cần hướng dẫn chi tiết hơn về bất kỳ bước nào hoặc gặp lỗi trong quá trình cài đặt, hãy cho tôi biết![](https://projectwhiteroom.blogspot.com/2021/07/huong-dan-cai-at-arch-linux-dual-boot.html)[](https://bkhost.vn/blog/arch-linux-install/)[](https://vinahost.vn/arch-linux-la-gi/)
