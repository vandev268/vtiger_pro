# Test Activity Tracking System

## Quick Test Script

```bash
# 1. Check table exists
mysql -u root -e "USE cusc_db_1; SHOW TABLES LIKE '%activity%';"

# 2. Check current sessions (before test)
mysql -u root -e "USE cusc_db_1; SELECT * FROM vtiger_user_activity_tracking;"

# 3. Login to CRM and do some activities

# 4. Check tracking is working
mysql -u root -e "USE cusc_db_1; SELECT * FROM vtiger_user_activity_tracking ORDER BY id DESC LIMIT 5;"

# 5. Compare with loginhistory
mysql -u root -e "USE cusc_db_1; 
SELECT 
    h.login_id,
    h.user_name,
    h.login_time,
    COALESCE(t.last_activity_time, h.login_time) as last_activity,
    h.logout_time,
    TIMESTAMPDIFF(MINUTE, h.login_time, COALESCE(t.last_activity_time, h.logout_time)) as duration_minutes,
    h.status
FROM vtiger_loginhistory h
LEFT JOIN vtiger_user_activity_tracking t ON h.login_id = t.login_id
WHERE h.status = 'Signed in'
ORDER BY h.login_id DESC 
LIMIT 5;"

# 6. Run cleanup script
cmd /c "c:\xampp\htdocs\cusc\cron\UpdateExpiredSessions.bat"

# 7. Check results
mysql -u root -e "USE cusc_db_1; 
SELECT 
    h.login_id,
    h.user_name,
    h.login_time,
    h.logout_time,
    TIMESTAMPDIFF(MINUTE, h.login_time, h.logout_time) as duration_minutes,
    h.status
FROM vtiger_loginhistory h
ORDER BY h.login_id DESC 
LIMIT 5;"
```

## Expected Results

### Before Activity Tracking:
```
+----------+-----------+---------------------+---------------------+------------------+-----------------+
| login_id | user_name | login_time          | logout_time         | duration_minutes | status          |
+----------+-----------+---------------------+---------------------+------------------+-----------------+
|       98 | admin     | 2025-11-18 11:58:20 | 2025-11-18 12:22:20 |               24 | Session expired |
```
**Problem:** Always 24 minutes (session timeout)

### After Activity Tracking:
```
+----------+-----------+---------------------+---------------------+------------------+-----------------+
| login_id | user_name | login_time          | logout_time         | duration_minutes | status          |
+----------+-----------+---------------------+---------------------+------------------+-----------------+
|       99 | admin     | 2025-11-18 13:00:00 | 2025-11-18 14:15:30 |               75 | Session expired |
```
**Solution:** Actual working time (75 minutes based on last activity)

## Test Scenarios

### Scenario 1: Normal Usage
1. Login at 13:00:00
2. Work until 14:15:30 (last activity)
3. Stop using (no more requests)
4. After 24 minutes idle, cleanup runs
5. Logout time = 14:15:30 (last activity)
6. Duration = 75 minutes ✅

### Scenario 2: Long Session
1. Login at 09:00:00
2. Work continuously until 17:30:00
3. Duration = 8.5 hours ✅

### Scenario 3: Short Session
1. Login at 10:00:00
2. Work for 10 minutes
3. Last activity at 10:10:00
4. Duration = 10 minutes ✅

## Verification Checklist

- [ ] Table `vtiger_user_activity_tracking` created successfully
- [ ] ActivityTracker.php file exists in includes/utils/
- [ ] WebUI.php updated to call ActivityTracker::updateActivity()
- [ ] Users/models/Module.php saves login_id to session
- [ ] UpdateExpiredSessions.php uses last_activity_time
- [ ] Login and see session tracked in activity table
- [ ] Navigate between pages and see last_activity_time updates
- [ ] Run cleanup and see accurate duration in Login History
- [ ] Duration is NOT always 24 minutes anymore

## Manual Test Steps

1. **Clear old sessions:**
   ```sql
   DELETE FROM vtiger_user_activity_tracking;
   ```

2. **Login to CRM**
   - Go to http://localhost/cusc
   - Login with your credentials

3. **Check session created:**
   ```sql
   SELECT * FROM vtiger_user_activity_tracking;
   ```
   Should show 1 row with current time

4. **Do some activities:**
   - Navigate to Contacts
   - View some records
   - Go to Organizations
   - etc.

5. **Check last_activity_time updates:**
   ```sql
   SELECT login_id, user_name, last_activity_time, updated_at 
   FROM vtiger_user_activity_tracking;
   ```
   The `updated_at` should change with each activity

6. **Wait 25+ minutes (or modify cutoff time for testing)**

7. **Run cleanup:**
   ```bash
   cmd /c "c:\xampp\htdocs\cusc\cron\UpdateExpiredSessions.bat"
   ```

8. **Check Login History in UI:**
   - Go to Settings > Login History
   - See "Thời gian hoạt động" column
   - Should show actual time worked, not 24 minutes

## Success Criteria

✅ **Activity tracking table populated on login**
✅ **Last activity time updates on each request**
✅ **Session duration calculated from last_activity_time**
✅ **Duration reflects actual working time**
✅ **No longer fixed at 24 minutes**
✅ **Works for time attendance (chấm công) purposes**

---
**Test Date:** 2025-11-18
**Status:** Ready for testing
