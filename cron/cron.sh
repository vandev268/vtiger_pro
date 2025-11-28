#!/bin/bash
# VtigerCRM Comprehensive Cron Job Runner
# Run all necessary cron jobs in sequence

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VTIGERCRM_ROOTDIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$VTIGERCRM_ROOTDIR/logs"
CRON_LOG="$LOG_DIR/cron_all.log"

mkdir -p "$LOG_DIR"
cd "$VTIGERCRM_ROOTDIR"

echo "============================================================"
echo "VtigerCRM - Running All Cron Jobs"
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

echo "" >> "$CRON_LOG"
echo "============================================================" >> "$CRON_LOG"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting All Cron Jobs" >> "$CRON_LOG"
echo "============================================================" >> "$CRON_LOG"

# 1. Main VtigerCRM Cron
echo "[$(date '+%H:%M:%S')] Running main VtigerCRM cron jobs..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running vtigercron.php" >> "$CRON_LOG"
php -f vtigercron.php >> "$CRON_LOG" 2>&1
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Main cron job completed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Main cron job completed"
else
    echo "[ERROR] Main cron job failed!" >> "$CRON_LOG"
    echo "[ERROR] Main cron job failed!"
fi

echo ""
echo "------------------------------------------------------------"

# 2. Update Expired Sessions
echo "[$(date '+%H:%M:%S')] Updating expired sessions..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running UpdateExpiredSessions.php" >> "$CRON_LOG"
php -f cron/UpdateExpiredSessions.php >> "$CRON_LOG" 2>&1
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Session cleanup completed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Session cleanup completed"
else
    echo "[ERROR] Session cleanup failed!" >> "$CRON_LOG"
    echo "[ERROR] Session cleanup failed!"
fi

echo ""
echo "------------------------------------------------------------"

# 3. Mail Scanner
echo "[$(date '+%H:%M:%S')] Running mail scanner..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running MailScanner service" >> "$CRON_LOG"
php -f vtigercron.php service=MailScanner >> "$CRON_LOG" 2>&1
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Mail scanner completed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Mail scanner completed"
else
    echo "[WARNING] Mail scanner failed or not configured" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Mail scanner completed (may be disabled)"
fi

echo ""
echo "------------------------------------------------------------"

# 4. Send Reminders
echo "[$(date '+%H:%M:%S')] Sending reminders..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running SendReminder service" >> "$CRON_LOG"
php -f vtigercron.php service=SendReminder >> "$CRON_LOG" 2>&1
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Send reminder completed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Send reminder completed"
else
    echo "[WARNING] Send reminder failed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Send reminder completed"
fi

echo ""
echo "------------------------------------------------------------"

# 5. Workflow Tasks
echo "[$(date '+%H:%M:%S')] Running workflow tasks..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running Workflow service" >> "$CRON_LOG"
php -f vtigercron.php service=Workflow >> "$CRON_LOG" 2>&1
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Workflow tasks completed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Workflow tasks completed"
else
    echo "[WARNING] Workflow tasks failed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Workflow tasks completed"
fi

echo ""
echo "------------------------------------------------------------"

# 6. Recurring Invoices
echo "[$(date '+%H:%M:%S')] Processing recurring invoices..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running RecurringInvoice service" >> "$CRON_LOG"
php -f vtigercron.php service=RecurringInvoice >> "$CRON_LOG" 2>&1
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Recurring invoices completed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Recurring invoices completed"
else
    echo "[WARNING] Recurring invoices failed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Recurring invoices completed"
fi

echo ""
echo "------------------------------------------------------------"

# 7. Scheduled Reports
echo "[$(date '+%H:%M:%S')] Running scheduled reports..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running ScheduleReports service" >> "$CRON_LOG"
php -f vtigercron.php service=ScheduleReports >> "$CRON_LOG" 2>&1
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Scheduled reports completed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Scheduled reports completed"
else
    echo "[WARNING] Scheduled reports failed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Scheduled reports completed"
fi

echo ""
echo "------------------------------------------------------------"

# 8. Scheduled Imports
echo "[$(date '+%H:%M:%S')] Running scheduled imports..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running ScheduledImport service" >> "$CRON_LOG"
php -f vtigercron.php service=ScheduledImport >> "$CRON_LOG" 2>&1
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Scheduled imports completed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Scheduled imports completed"
else
    echo "[WARNING] Scheduled imports failed" >> "$CRON_LOG"
    echo "[$(date '+%H:%M:%S')] Scheduled imports completed"
fi

echo ""
echo "============================================================"
echo "[$(date '+%H:%M:%S')] All cron jobs completed!"
echo "============================================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] All cron jobs completed successfully" >> "$CRON_LOG"
echo "============================================================" >> "$CRON_LOG"
echo "" >> "$CRON_LOG"
