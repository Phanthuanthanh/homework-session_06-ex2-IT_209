# Báo cáo Thực hành - Bài 2: Cấu hình phân quyền Nhóm và sudoers bằng visudo

---

## 1. Mục tiêu bài tập
- Nắm vững thao tác quản lý người dùng (User) và nhóm (Group) trên hệ điều hành Linux.
- Hiểu rõ cơ chế cấp quyền quản trị của lệnh `sudo` và tệp cấu hình `/etc/sudoers`.
- Cấu hình phân quyền an toàn, áp dụng nguyên tắc đặc quyền tối thiểu (Principle of Least Privilege): Chỉ cho phép tài khoản `deployer` thuộc nhóm `devops-admin` thực thi các lệnh quản lý dịch vụ hệ thống (`systemctl`) với các hành vi `start`, `stop`, `restart`, `status` mà không cần nhập mật khẩu (`NOPASSWD`), đồng thời ngăn chặn truy cập toàn quyền root.

---

## 2. Các bước triển khai

### Bước 1: Tạo nhóm người dùng `devops-admin`
Sử dụng lệnh `groupadd` để tạo nhóm quản trị vận hành:
```bash
sudo groupadd devops-admin
```

### Bước 2: Tạo người dùng `deployer` và gán vào nhóm `devops-admin`
Tạo người dùng mới và đưa vào nhóm `devops-admin`:
```bash
sudo useradd -m -s /bin/bash deployer
sudo usermod -aG devops-admin deployer
```

Đặt mật khẩu cho người dùng `deployer`:
```bash
echo "deployer:deployer123" | sudo chpasswd
```

Kiểm tra thông tin tài khoản và nhóm:
```bash
id deployer
groups deployer
```

### Bước 3: Cấu hình `/etc/sudoers` an toàn bằng `visudo`
Mở tệp cấu hình bằng lệnh:
```bash
sudo visudo
```

Thêm quy tắc phân quyền cho nhóm `devops-admin` vào cuối tệp:
```text
%devops-admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

Kiểm tra tính hợp lệ của cú pháp cấu hình:
```bash
sudo visudo -c
```

---

## 3. Trích dẫn dòng cấu hình sudoers đã thêm vào hệ thống

Dòng cấu hình đã được thêm vào cuối tệp `/etc/sudoers`:

```sudoers
%devops-admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

### Giải thích các thành phần:
- `%devops-admin`: Ký tự `%` biểu thị quy tắc áp dụng cho Group `devops-admin`. Bất kỳ người dùng nào thuộc nhóm này đều thừa hưởng chính sách.
- `ALL=`: Quy tắc có hiệu lực trên tất cả các host máy chủ.
- `(ALL)`: Cho phép thực thi lệnh dưới danh nghĩa của mọi user (mặc định là root).
- `NOPASSWD:`: Không yêu cầu người dùng nhập mật khẩu xác thực khi gọi `sudo` với các lệnh được chỉ định phía sau (phục vụ tự động hóa CI/CD / Deployment scripts).
- `/usr/bin/systemctl start *, ...`: Đường dẫn tuyệt đối đến binary thực thi, chỉ cho phép các subcommand `start`, `stop`, `restart`, `status` cho mọi dịch vụ hệ thống.

---

## 4. Kết quả kiểm tra (Terminal Output)

### 4.1. Kiểm tra thông tin người dùng và nhóm
```bash
$ id deployer
uid=1001(deployer) gid=1002(deployer) groups=1002(deployer),1001(devops-admin)

$ groups deployer
deployer : deployer devops-admin
```

### 4.2. Chuyển sang tài khoản `deployer` và kiểm tra quyền `sudo -l`
```bash
$ su - deployer
Password: 

$ sudo -l
User deployer may run the following commands on MSI:
    (ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

### 4.3. Kiểm tra khởi động lại dịch vụ hệ thống `cron`
Lệnh thực thi không yêu cầu nhập mật khẩu và thành công ngay lập tức:
```bash
$ sudo systemctl restart cron
```

Kiểm tra trạng thái dịch vụ `cron` sau khi khởi động lại:
```bash
$ sudo systemctl status cron --no-pager
● cron.service - Regular background program processing daemon
     Loaded: loaded (/usr/lib/systemd/system/cron.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-10-06 08:13:00 UTC; 44ms ago
 Invocation: 2660c8ef668e48f19f443427bd3dedd6
       Docs: man:cron(8)
   Main PID: 1121 (cron)
      Tasks: 1 (limit: 9338)
     Memory: 560K (peak: 1.7M)
        CPU: 16ms
     CGroup: /system.slice/cron.service
             └─1121 /usr/sbin/cron -f -P

Oct 06 08:13:00 MSI systemd[1]: cron.service: Deactivated successfully.
Oct 06 08:13:00 MSI systemd[1]: Stopped cron.service - Regular background program processing daemon.
Oct 06 08:13:00 MSI systemd[1]: Started cron.service - Regular background program processing daemon.
Oct 06 08:13:00 MSI (cron)[1121]: cron.service: Referenced but unset environment variable evaluates to an empty string: EXTRA_OPTS
Oct 06 08:13:00 MSI cron[1121]: (CRON) INFO (pidfile fd = 3)
Oct 06 08:13:00 MSI cron[1121]: (CRON) INFO (Skipping @reboot jobs -- not system startup)
```

### 4.4. Kiểm tra giới hạn quyền bảo mật (Negative Test)
Thử chạy lệnh ngoài phạm vi cho phép (ví dụ đọc file nhạy cảm `/etc/shadow`):
```bash
$ sudo cat /etc/shadow
sudo: I'm sorry deployer. I'm afraid I can't do that
```
Hệ thống từ chối thực thi do `deployer` không có đặc quyền root tổng thể.

---

## 5. Kết luận
- Hệ thống đã được cấu hình chính xác theo đúng yêu cầu đề bài.
- Người dùng `deployer` có toàn quyền điều khiển vòng đời các dịch vụ (`start`, `stop`, `restart`, `status`) mà không bị gián đoạn bởi prompt mật khẩu.
- An toàn hệ thống được đảm bảo theo chuẩn DevOps do không cấp full root privilege cho tài khoản triển khai.
