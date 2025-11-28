# Hướng Dẫn Cài Đặt Cron Trên Linux Server

## Bước 1: Upload và Chuẩn Bị File

### 1.1. Upload file lên server
```bash
# Upload file cron.sh lên /var/www/html/cusc/cron/
```

### 1.2. Chuyển đổi line endings từ Windows sang Unix
```bash
cd /var/www/html/cusc/cron
dos2unix cron.sh
# Hoặc nếu không có dos2unix:
sed -i 's/\r$//' cron.sh
```

### 1.3. Cấp quyền thực thi
```bash
chmod +x cron.sh
```

## Bước 2: Kiểm Tra và Test

### 2.1. Kiểm tra quyền
```bash
ls -la /var/www/html/cusc/cron/cron.sh
# Kết quả nên là: -rwxr-xr-x
```

### 2.2. Test chạy script
```bash
cd /var/www/html/cusc/cron
bash cron.sh
# Hoặc
./cron.sh
```

### 2.3. Kiểm tra log
```bash
tail -f /var/www/html/cusc/logs/cron_all.log
```

## Bước 3: Cài Đặt Crontab

### 3.1. Mở crontab editor
```bash
crontab -e
```

### 3.2. Thêm dòng sau (chạy mỗi 15 phút)
```cron
*/15 * * * * /bin/bash /var/www/html/cusc/cron/cron.sh >> /var/www/html/cusc/logs/cron_output.log 2>&1
```

### 3.3. Các tùy chọn khác:

**Chạy mỗi 30 phút:**
```cron
*/30 * * * * /bin/bash /var/www/html/cusc/cron/cron.sh >> /var/www/html/cusc/logs/cron_output.log 2>&1
```

**Chạy mỗi giờ:**
```cron
0 * * * * /bin/bash /var/www/html/cusc/cron/cron.sh >> /var/www/html/cusc/logs/cron_output.log 2>&1
```

**Chạy mỗi 10 phút:**
```cron
*/10 * * * * /bin/bash /var/www/html/cusc/cron/cron.sh >> /var/www/html/cusc/logs/cron_output.log 2>&1
```

### 3.4. Lưu và thoát
- Với vi/vim: Nhấn `Esc`, gõ `:wq`, nhấn Enter
- Với nano: Nhấn `Ctrl+X`, nhấn `Y`, nhấn Enter

### 3.5. Kiểm tra crontab đã được thêm
```bash
crontab -l
```

## Bước 4: Khắc Phục Sự Cố

### 4.1. Lỗi "cannot open cron: No such file"
```bash
# Đảm bảo file tồn tại
ls -la /var/www/html/cusc/cron/cron.sh

# Chạy với đường dẫn đầy đủ
bash /var/www/html/cusc/cron/cron.sh
```

### 4.2. Lỗi "bad interpreter"
```bash
# Chuyển đổi line endings
sed -i 's/\r$//' /var/www/html/cusc/cron/cron.sh

# Hoặc cài đặt dos2unix
apt-get install dos2unix
dos2unix /var/www/html/cusc/cron/cron.sh
```

### 4.3. Lỗi "Permission denied"
```bash
# Cấp quyền owner
chown www-data:www-data /var/www/html/cusc/cron/cron.sh

# Cấp quyền thực thi
chmod +x /var/www/html/cusc/cron/cron.sh

# Tạo thư mục logs và cấp quyền
mkdir -p /var/www/html/cusc/logs
chown -R www-data:www-data /var/www/html/cusc/logs
chmod -R 755 /var/www/html/cusc/logs
```

### 4.4. Lỗi PHP không tìm thấy
```bash
# Kiểm tra PHP path
which php

# Nếu PHP ở vị trí khác, sửa trong script:
# Thay "php" bằng đường dẫn đầy đủ như "/usr/bin/php" hoặc "/usr/bin/php8.1"
```

### 4.5. Cron không chạy tự động
```bash
# Kiểm tra cron service đang chạy
systemctl status cron
# Hoặc
service cron status

# Khởi động lại cron service
systemctl restart cron
# Hoặc
service cron restart

# Kiểm tra log của cron system
tail -f /var/log/syslog | grep CRON
```

## Bước 5: Giám Sát

### 5.1. Xem log cron realtime
```bash
tail -f /var/www/html/cusc/logs/cron_all.log
```

### 5.2. Xem log output
```bash
tail -f /var/www/html/cusc/logs/cron_output.log
```

### 5.3. Xem system cron log
```bash
tail -f /var/log/syslog | grep CRON
```

### 5.4. Kiểm tra kích thước log
```bash
du -h /var/www/html/cusc/logs/
```

### 5.5. Dọn dẹp log cũ (tùy chọn)
```bash
# Xóa log cũ hơn 30 ngày
find /var/www/html/cusc/logs/ -name "*.log" -mtime +30 -delete

# Hoặc truncate log hiện tại
truncate -s 0 /var/www/html/cusc/logs/cron_all.log
```

## Bước 6: Script Tự Động Setup

Tạo file `setup_cron.sh` để tự động hóa:

```bash
#!/bin/bash
echo "Setting up VtigerCRM Cron Jobs..."

CRON_DIR="/var/www/html/cusc/cron"
CRON_SCRIPT="$CRON_DIR/cron.sh"
LOG_DIR="/var/www/html/cusc/logs"

# Convert line endings
echo "Converting line endings..."
sed -i 's/\r$//' "$CRON_SCRIPT"

# Set permissions
echo "Setting permissions..."
chmod +x "$CRON_SCRIPT"
mkdir -p "$LOG_DIR"
chown -R www-data:www-data "$LOG_DIR"
chmod -R 755 "$LOG_DIR"

# Test run
echo "Testing cron script..."
bash "$CRON_SCRIPT"

# Add to crontab
echo "Adding to crontab..."
CRON_ENTRY="*/15 * * * * /bin/bash $CRON_SCRIPT >> $LOG_DIR/cron_output.log 2>&1"
(crontab -l 2>/dev/null | grep -v "$CRON_SCRIPT"; echo "$CRON_ENTRY") | crontab -

echo "Setup complete!"
echo "Check logs at: $LOG_DIR/cron_all.log"
```

Chạy script setup:
```bash
chmod +x setup_cron.sh
sudo ./setup_cron.sh
```

## Ghi Chú Quan Trọng

1. **Đường dẫn tuyệt đối**: Luôn dùng đường dẫn đầy đủ trong crontab
2. **Quyền truy cập**: Đảm bảo user chạy cron có quyền truy cập file
3. **PHP path**: Kiểm tra PHP có trong PATH hoặc dùng đường dẫn đầy đủ
4. **Log rotation**: Thiết lập logrotate để tránh log quá lớn
5. **Timezone**: Đảm bảo timezone server đúng

## Tham Khảo

- Kiểm tra cron syntax: https://crontab.guru/
- VtigerCRM Documentation: https://wiki.vtiger.com/
- Linux cron guide: `man cron`
