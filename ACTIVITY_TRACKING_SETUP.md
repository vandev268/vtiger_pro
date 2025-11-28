# Hướng dẫn cài đặt Activity Tracking cho chấm công

## Bước 1: Tạo bảng tracking trong database

Chạy script SQL để tạo bảng:

```bash
mysql -u root cusc_db_1 < migrate/20251118_create_user_activity_tracking.sql
```

Hoặc chạy SQL trực tiếp:

```sql
USE cusc_db_1;

CREATE TABLE IF NOT EXISTS vtiger_user_activity_tracking (
    id INT AUTO_INCREMENT PRIMARY KEY,
    login_id INT NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    last_activity_time DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_login_id (login_id),
    INDEX idx_user_name (user_name),
    INDEX idx_last_activity (last_activity_time),
    FOREIGN KEY (login_id) REFERENCES vtiger_loginhistory(login_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Track user activity for accurate time tracking';
```

## Bước 2: Kiểm tra các file đã được cập nhật

✅ **includes/utils/ActivityTracker.php** - Class theo dõi hoạt động
✅ **includes/main/WebUI.php** - Tích hợp tracking vào mọi request
✅ **modules/Users/models/Module.php** - Lưu login_id vào session
✅ **cron/UpdateExpiredSessions.php** - Dùng last_activity_time thay vì timeout

## Bước 3: Test hoạt động

### A. Kiểm tra bảng đã tạo thành công

```bash
mysql -u root -e "USE cusc_db_1; DESCRIBE vtiger_user_activity_tracking;"
```

### B. Test luồng hoạt động

1. **Đăng nhập vào hệ thống**
   - Login vào CRM
   - Kiểm tra session có login_id không

2. **Thực hiện các hoạt động**
   - Navigate giữa các module
   - Tạo/sửa/xóa records
   - Mỗi request sẽ update last_activity_time

3. **Kiểm tra tracking table**
   ```sql
   USE cusc_db_1;
   SELECT * FROM vtiger_user_activity_tracking ORDER BY id DESC LIMIT 5;
   ```

   Kết quả mong đợi:
   ```
   +----+----------+-----------+---------------------+---------------------+---------------------+
   | id | login_id | user_name | last_activity_time  | created_at          | updated_at          |
   +----+----------+-----------+---------------------+---------------------+---------------------+
   | 1  | 99       | admin     | 2025-11-18 13:45:30 | 2025-11-18 13:20:00 | 2025-11-18 13:45:30 |
   +----+----------+-----------+---------------------+---------------------+---------------------+
   ```

4. **Đợi một thời gian rồi chạy cleanup**
   ```bash
   cmd /c "c:\xampp\htdocs\cusc\cron\UpdateExpiredSessions.bat"
   ```

5. **Kiểm tra Login History**
   - Vào Settings > Login History
   - Xem cột "Thời gian hoạt động"
   - Thời gian sẽ được tính từ login_time đến last_activity_time (không còn cố định 24 phút)

### C. Test chi tiết

```sql
-- Kiểm tra session duration với last_activity
SELECT 
    h.login_id,
    h.user_name,
    h.login_time,
    h.logout_time,
    COALESCE(t.last_activity_time, h.login_time) as last_activity,
    TIMESTAMPDIFF(MINUTE, h.login_time, COALESCE(t.last_activity_time, h.logout_time)) as duration_minutes,
    h.status
FROM vtiger_loginhistory h
LEFT JOIN vtiger_user_activity_tracking t ON h.login_id = t.login_id
ORDER BY h.login_id DESC 
LIMIT 5;
```

## Bước 4: Monitoring và bảo trì

### Monitor logs
```bash
tail -f logs/session_cleanup.log
```

### Dọn dẹp tracking cũ (tùy chọn)
Thêm vào cron để dọn dẹp records cũ hơn 30 ngày:

```php
// Thêm vào cron/UpdateExpiredSessions.php
require_once 'includes/utils/ActivityTracker.php';
$cleanedCount = ActivityTracker::cleanup(30); // Delete records older than 30 days
echo "Cleaned {$cleanedCount} old tracking records\n";
```

## Cách hoạt động của hệ thống mới

### Before (Vấn đề cũ):
```
Login: 11:00:00
Logout: 11:24:00 (login_time + 24 phút - LUÔN CỐ ĐỊNH)
Duration: 24 phút (SAI - không phản ánh thời gian thực)
```

### After (Giải pháp mới):
```
Login: 11:00:00
Last activity: 11:45:30 (theo dõi mỗi request)
Logout: 11:45:30 (= last_activity_time)
Duration: 45 phút (ĐÚNG - phản ánh thời gian làm việc thực tế)
```

## Lợi ích cho chấm công

✅ **Chính xác**: Thời gian làm việc thực tế, không còn cố định 24 phút
✅ **Tự động**: Tracking diễn ra tự động ở mọi request
✅ **Hiệu quả**: Không ảnh hưởng đến performance
✅ **Linh hoạt**: Có thể điều chỉnh session timeout tùy ý
✅ **Đáng tin cậy**: Dữ liệu được lưu vào database, không mất khi restart

## Troubleshooting

### Vấn đề: Tracking không hoạt động
**Giải pháp:**
1. Kiểm tra bảng đã tạo: `SHOW TABLES LIKE '%tracking%';`
2. Kiểm tra file ActivityTracker.php tồn tại
3. Kiểm tra logs: `tail logs/error.log`

### Vấn đề: Vẫn hiển thị 24 phút
**Giải pháp:**
1. Xóa session cũ và login lại
2. Kiểm tra tracking table có dữ liệu không
3. Chạy lại UpdateExpiredSessions.php

### Vấn đề: Login_id không được lưu vào session
**Giải pháp:**
1. Kiểm tra file Users/models/Module.php đã được update
2. Logout và login lại
3. Check session: `var_dump($_SESSION['login_id']);`

## Kết luận

Hệ thống bây giờ sẽ:
- ✅ Theo dõi thời gian hoạt động THỰC TẾ của nhân viên
- ✅ Không còn giới hạn bởi session timeout 24 phút
- ✅ Chính xác cho mục đích chấm công
- ✅ Tự động cập nhật mỗi khi có hoạt động

---
**Ngày tạo:** 2025-11-18
**Mục đích:** Cải thiện hệ thống chấm công nhân viên
