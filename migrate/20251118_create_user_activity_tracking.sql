-- =====================================================
-- Create User Activity Tracking Table
-- Purpose: Track actual user activity time for accurate time tracking
-- Date: 2025-11-18
-- =====================================================

-- Create table to track user last activity time
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

-- Note: This table will be updated on every user request to track actual activity
-- The UpdateExpiredSessions.php script will use last_activity_time 
-- instead of login_time + timeout for accurate logout time
