# VẤN ĐỀ: Thời gian hoạt động luôn hiển thị 24 phút

## Triệu chứng
Tất cả các session trong Login History đều hiển thị "24 phút 0 giây" bất kể người dùng thực sự đã sử dụng hệ thống trong bao lâu.

## Nguyên nhân gốc rễ

### 1. Session Timeout mặc định
```
session.gc_maxlifetime = 1440 seconds = 24 minutes
```

### 2. Script UpdateExpiredSessions.php
File `cron/UpdateExpiredSessions.php` được chạy định kỳ để dọn dẹp các session hết hạn. Script này:

```php
// Dòng 64-65: Tính toán logout time ước tính
$estimatedLogoutTime = date('Y-m-d H:i:s', strtotime($loginTime) + $sessionTimeout);
```

**VẤN ĐỀ:** Script này set `logout_time = login_time + 1440 giây` cho TẤT CẢ các session hết hạn, bất kể người dùng thực tế có đang active hay không.

### 3. Database Query
File `modules/Settings/LoginHistory/models/ListView.php` tính duration:

```sql
TIMESTAMPDIFF(SECOND, vtiger_loginhistory.login_time, vtiger_loginhistory.logout_time) AS session_duration
```

Kết quả: `logout_time - login_time = 1440 giây = 24 phút` cho tất cả session hết hạn.

### 4. Kết quả thực tế từ database

```
mysql> SELECT login_id, user_name, login_time, logout_time, 
       TIMESTAMPDIFF(SECOND, login_time, logout_time) AS duration_seconds 
       FROM vtiger_loginhistory ORDER BY login_id DESC LIMIT 5;

+----------+-----------+---------------------+---------------------+------------------+
| login_id | user_name | login_time          | logout_time         | duration_seconds |
+----------+-----------+---------------------+---------------------+------------------+
|       98 | admin     | 2025-11-18 11:58:20 | 2025-11-18 12:22:20 |             1440 |
|       97 | admin     | 2025-11-17 14:26:10 | 2025-11-17 14:50:10 |             1440 |
|       96 | Van       | 2025-11-17 13:10:28 | 2025-11-17 13:34:28 |             1440 |
|       95 | Van       | 2025-11-17 13:09:55 | 2025-11-17 13:33:55 |             1440 |
|       94 | admin     | 2025-11-17 12:38:23 | 2025-11-17 13:02:23 |             1440 |
+----------+-----------+---------------------+---------------------+------------------+
```

## Giải pháp

### Tùy chọn 1: Tăng session timeout (KHUYẾN NGHỊ)
Tăng thời gian session timeout để phù hợp với thời gian làm việc thực tế.

**Cách 1: Sửa php.ini**
```ini
; File: C:\xampp\php\php.ini
session.gc_maxlifetime = 7200  ; 2 giờ
; hoặc
session.gc_maxlifetime = 14400 ; 4 giờ
```

**Cách 2: Sửa trong code**
```php
// File: includes/main/WebUI.php hoặc config.inc.php
ini_set('session.gc_maxlifetime', 7200); // 2 giờ
```

### Tùy chọn 2: Theo dõi hoạt động thực tế của người dùng

Để theo dõi chính xác thời gian người dùng thực sự active, cần:

#### A. Tạo bảng tracking hoạt động
```sql
CREATE TABLE IF NOT EXISTS vtiger_user_activity_tracking (
    id INT AUTO_INCREMENT PRIMARY KEY,
    login_id INT NOT NULL,
    user_name VARCHAR(100),
    last_activity_time DATETIME,
    INDEX idx_login_id (login_id),
    INDEX idx_last_activity (last_activity_time)
);
```

#### B. Cập nhật last_activity_time mỗi khi có request
```php
// Thêm vào includes/main/WebUI.php
function updateUserActivity() {
    global $adb, $current_user;
    if (isset($_SESSION['login_id'])) {
        $loginId = $_SESSION['login_id'];
        $currentTime = date('Y-m-d H:i:s');
        
        $checkQuery = "SELECT id FROM vtiger_user_activity_tracking WHERE login_id = ?";
        $result = $adb->pquery($checkQuery, array($loginId));
        
        if ($adb->num_rows($result) > 0) {
            $updateQuery = "UPDATE vtiger_user_activity_tracking 
                          SET last_activity_time = ? 
                          WHERE login_id = ?";
            $adb->pquery($updateQuery, array($currentTime, $loginId));
        } else {
            $insertQuery = "INSERT INTO vtiger_user_activity_tracking 
                          (login_id, user_name, last_activity_time) 
                          VALUES (?, ?, ?)";
            $adb->pquery($insertQuery, array($loginId, $current_user->user_name, $currentTime));
        }
    }
}

// Gọi function này sau khi authenticate
updateUserActivity();
```

#### C. Sửa UpdateExpiredSessions.php để dùng last_activity_time
```php
// Thay vì dùng login_time + session_timeout
// Dùng last_activity_time từ tracking table

$query = "SELECT h.login_id, h.user_name, h.login_time, h.logout_time, 
          IFNULL(t.last_activity_time, h.login_time) as last_activity
          FROM vtiger_loginhistory h
          LEFT JOIN vtiger_user_activity_tracking t ON h.login_id = t.login_id
          WHERE h.status = 'Signed in' 
          AND IFNULL(t.last_activity_time, h.login_time) < ?";

// Set logout_time = last_activity_time thay vì login_time + timeout
$estimatedLogoutTime = $row['last_activity'];
```

### Tùy chọn 3: Chấp nhận 24 phút là "default timeout"

Nếu không cần theo dõi thời gian chính xác:
- Giữ nguyên hiện tại
- Hiểu rằng "24 phút" có nghĩa là "tối thiểu 24 phút hoặc hơn"
- Session thực tế có thể dài hơn nếu người dùng vẫn active

## Khuyến nghị

**Giải pháp ngắn hạn (KHUYẾN NGHỊ):**
1. Tăng `session.gc_maxlifetime` lên 2-4 giờ
2. Restart Apache
3. Chạy lại UpdateExpiredSessions.bat

**Giải pháp dài hạn (nếu cần tracking chính xác):**
1. Implement Tùy chọn 2 - Activity Tracking
2. Tạo bảng tracking
3. Update code để track last activity
4. Sửa cleanup script để dùng last activity time

## Kiểm tra sau khi fix

```bash
# 1. Kiểm tra session timeout mới
C:\xampp\php\php.exe -r "echo ini_get('session.gc_maxlifetime');"

# 2. Login và đợi > 24 phút nhưng < session timeout mới
# 3. Kiểm tra Login History xem còn hiển thị 24 phút hay không

# 4. Kiểm tra database
mysql -u root cusc_db_1 -e "SELECT login_id, user_name, login_time, logout_time, 
    TIMESTAMPDIFF(MINUTE, login_time, logout_time) AS duration_minutes 
    FROM vtiger_loginhistory ORDER BY login_id DESC LIMIT 5;"
```

## Tóm tắt

✅ **Vấn đề đã xác định:** UpdateExpiredSessions.php set logout_time = login_time + 1440s cho tất cả session hết hạn

✅ **Giải pháp nhanh:** Tăng session.gc_maxlifetime trong php.ini lên 2-4 giờ

✅ **Giải pháp đầy đủ:** Implement activity tracking để theo dõi thời gian active thực tế

---
**Ngày tạo:** 2025-11-18
**Người tạo:** GitHub Copilot
