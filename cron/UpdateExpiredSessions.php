<?php
/*+**********************************************************************************
 * Auto Update Logout Time for Expired Sessions
 * Run this via cron every 5-10 minutes
 * php cron/UpdateExpiredSessions.php
 ************************************************************************************/

// Change to the root directory
chdir(dirname(__FILE__) . '/..');

// Include VTiger core
require_once 'includes/main/WebUI.php';

global $adb;
$adb = PearDatabase::getInstance();

if (!$adb) {
    die("ERROR: Could not connect to database\n");
}

echo "[" . date('Y-m-d H:i:s') . "] Starting session cleanup...\n";

// Get session timeout from config (default 30 minutes)
$sessionTimeout = ini_get('session.gc_maxlifetime');
if (empty($sessionTimeout)) {
    $sessionTimeout = 1800; // 30 minutes default
}

// Calculate the cutoff time
$cutoffTime = date('Y-m-d H:i:s', time() - $sessionTimeout);

echo "Session timeout: {$sessionTimeout} seconds (" . ($sessionTimeout / 60) . " minutes)\n";
echo "Cutoff time: {$cutoffTime}\n";

// Find all sessions that are still "Signed in" but last activity is older than cutoff
// Use last_activity_time from tracking table if available, otherwise use login_time
$query = "SELECT h.login_id, h.user_name, h.user_ip, h.login_time, h.logout_time,
          COALESCE(t.last_activity_time, h.login_time) as last_activity
          FROM vtiger_loginhistory h
          LEFT JOIN vtiger_user_activity_tracking t ON h.login_id = t.login_id
          WHERE h.status = 'Signed in' 
          AND COALESCE(t.last_activity_time, h.login_time) < ?
          ORDER BY h.login_time ASC";

$result = $adb->pquery($query, array($cutoffTime));
$rowCount = $adb->num_rows($result);

echo "Found {$rowCount} expired sessions to update\n";

if ($rowCount > 0) {
    $updatedCount = 0;
    
    while ($row = $adb->fetchByAssoc($result)) {
        $loginId = $row['login_id'];
        $userName = $row['user_name'];
        $loginTime = $row['login_time'];
        $lastActivity = $row['last_activity'];
        
        // Use last_activity_time as logout time (actual last activity)
        // This gives accurate time tracking for attendance (chấm công)
        $logoutTime = $lastActivity;
        
        // Update the logout time
        $updateQuery = "UPDATE vtiger_loginhistory 
                       SET logout_time = ?, 
                           status = 'Session expired' 
                       WHERE login_id = ?";
        
        $updateResult = $adb->pquery($updateQuery, array($logoutTime, $loginId));
        
        if ($updateResult) {
            $updatedCount++;
            $duration = strtotime($logoutTime) - strtotime($loginTime);
            $durationMinutes = round($duration / 60);
            echo "  Updated login_id {$loginId} for user '{$userName}' - logout: {$logoutTime} (duration: {$durationMinutes} mins)\n";
        } else {
            echo "  ERROR: Failed to update login_id {$loginId}\n";
        }
    }
    
    echo "\nSummary:\n";
    echo "  Total expired sessions: {$rowCount}\n";
    echo "  Successfully updated: {$updatedCount}\n";
    echo "  Failed: " . ($rowCount - $updatedCount) . "\n";
} else {
    echo "No expired sessions found\n";
}

// Also update sessions where logout_time equals login_time (incomplete logouts)
echo "\n[" . date('Y-m-d H:i:s') . "] Checking for incomplete logout records...\n";

$incompleteQuery = "SELECT h.login_id, h.user_name, h.login_time, h.logout_time,
                    COALESCE(t.last_activity_time, h.login_time) as last_activity
                    FROM vtiger_loginhistory h
                    LEFT JOIN vtiger_user_activity_tracking t ON h.login_id = t.login_id
                    WHERE h.logout_time = h.login_time 
                    AND h.login_time < ?
                    AND h.status = 'Signed in'";

$incompleteResult = $adb->pquery($incompleteQuery, array($cutoffTime));
$incompleteCount = $adb->num_rows($incompleteResult);

echo "Found {$incompleteCount} incomplete logout records\n";

if ($incompleteCount > 0) {
    $fixedCount = 0;
    
    while ($row = $adb->fetchByAssoc($incompleteResult)) {
        $loginId = $row['login_id'];
        $userName = $row['user_name'];
        $loginTime = $row['login_time'];
        $lastActivity = $row['last_activity'];
        
        // Use last_activity_time as logout time
        $logoutTime = $lastActivity;
        
        $updateQuery = "UPDATE vtiger_loginhistory 
                       SET logout_time = ?, 
                           status = 'Session expired' 
                       WHERE login_id = ?";
        
        if ($adb->pquery($updateQuery, array($logoutTime, $loginId))) {
            $fixedCount++;
            $duration = strtotime($logoutTime) - strtotime($loginTime);
            $durationMinutes = round($duration / 60);
            echo "  Fixed login_id {$loginId} for user '{$userName}' - duration: {$durationMinutes} mins\n";
        }
    }
    
    echo "Fixed {$fixedCount} incomplete logout records\n";
}

echo "\n[" . date('Y-m-d H:i:s') . "] Session cleanup completed\n";
echo "====================================\n\n";
