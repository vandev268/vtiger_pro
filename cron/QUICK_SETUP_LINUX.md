# Hướng Dẫn Nhanh - Cài Đặt Cron Trên Linux Server

## Cách 1: Tự Động (Khuyến Nghị)

```bash
# Vào thư mục cron
cd /var/www/html/cusc/cron

# Chuyển đổi line endings cho script setup
sed -i 's/\r$//' setup_cron.sh

# Cấp quyền thực thi
chmod +x setup_cron.sh

# Chạy script setup
bash setup_cron.sh
```

Script sẽ tự động:
- Chuyển đổi line endings
- Cấp quyền thực thi
- Tạo thư mục logs
- Test chạy script
- Thêm vào crontab (chạy mỗi 15 phút)

## Cách 2: Thủ Công

```bash
# Bước 1: Vào thư mục cron
cd /var/www/html/cusc/cron

# Bước 2: Chuyển đổi line endings
sed -i 's/\r$//' cron.sh

# Bước 3: Cấp quyền thực thi
chmod +x cron.sh

# Bước 4: Test chạy
bash cron.sh

# Bước 5: Thêm vào crontab
crontab -e
```

Thêm dòng sau vào crontab:
```
*/15 * * * * /bin/bash /var/www/html/cusc/cron/cron.sh >> /var/www/html/cusc/logs/cron_output.log 2>&1
```

## Kiểm Tra

```bash
# Xem crontab hiện tại
crontab -l

# Xem log realtime
tail -f /var/www/html/cusc/logs/cron_all.log

# Kiểm tra cron service
systemctl status cron
```

## Khắc Phục Lỗi

### Lỗi "bad interpreter" hoặc "not found"
```bash
sed -i 's/\r$//' /var/www/html/cusc/cron/cron.sh
```

### Lỗi "Permission denied"
```bash
chmod +x /var/www/html/cusc/cron/cron.sh
mkdir -p /var/www/html/cusc/logs
chmod -R 755 /var/www/html/cusc/logs
```

### Cron không chạy
```bash
# Khởi động lại cron service
systemctl restart cron

# Kiểm tra system log
tail -f /var/log/syslog | grep CRON
```

## Các File

- `cron.sh` - Script chính chạy tất cả cron jobs
- `setup_cron.sh` - Script tự động cài đặt
- `LINUX_SETUP_GUIDE.md` - Hướng dẫn chi tiết

## Tần Suất Chạy Khác

Sửa dòng crontab:

**Mỗi 10 phút:**
```
*/10 * * * * /bin/bash /var/www/html/cusc/cron/cron.sh >> /var/www/html/cusc/logs/cron_output.log 2>&1
```

**Mỗi 30 phút:**
```
*/30 * * * * /bin/bash /var/www/html/cusc/cron/cron.sh >> /var/www/html/cusc/logs/cron_output.log 2>&1
```

**Mỗi giờ:**
```
0 * * * * /bin/bash /var/www/html/cusc/cron/cron.sh >> /var/www/html/cusc/logs/cron_output.log 2>&1
```

## Ghi Chú

- Script sẽ tự động detect đúng thư mục gốc của VtigerCRM
- Tất cả logs được lưu trong `/var/www/html/cusc/logs/`
- Cron chạy các tasks: main cron, session cleanup, mail scanner, reminders, workflows, recurring invoices, reports, imports

Xem chi tiết trong `LINUX_SETUP_GUIDE.md`
