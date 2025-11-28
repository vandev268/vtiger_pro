@echo OFF
REM #*********************************************************************************
REM # Comprehensive Cron Job Runner for VtigerCRM
REM # This script runs all necessary cron jobs in sequence
REM # Recommended: Schedule this to run every 15-30 minutes via Windows Task Scheduler
REM #
REM # The contents of this file are subject to the vtiger CRM Public License Version 1.0
REM # ("License"); You may not use this file except in compliance with the License
REM # The Original Code is:  vtiger CRM Open Source
REM # Portions created by vtiger are Copyright (C) vtiger.
REM # All Rights Reserved.
REM #*********************************************************************************

echo ============================================================
echo VtigerCRM - Running All Cron Jobs
echo Started at: %date% %time%
echo ============================================================

REM Set paths
set VTIGERCRM_ROOTDIR=C:\xampp\htdocs\cusc
set PHP_EXE=C:\xampp\php\php.exe
set LOG_DIR=%VTIGERCRM_ROOTDIR%\logs
set CRON_LOG=%LOG_DIR%\cron_all.log

REM Create logs directory if it doesn't exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Change to VtigerCRM root directory
cd /D "%VTIGERCRM_ROOTDIR%"

echo. >> "%CRON_LOG%"
echo ============================================================ >> "%CRON_LOG%"
echo [%date% %time%] Starting All Cron Jobs >> "%CRON_LOG%"
echo ============================================================ >> "%CRON_LOG%"

REM 1. Run Main VtigerCRM Cron (includes workflows, scheduled reports, etc.)
echo [%time%] Running main VtigerCRM cron jobs...
echo [%date% %time%] Running vtigercron.php >> "%CRON_LOG%"
%PHP_EXE% -f vtigercron.php >> "%CRON_LOG%" 2>&1
if errorlevel 1 (
    echo [ERROR] Main cron job failed! >> "%CRON_LOG%"
    echo [ERROR] Main cron job failed!
) else (
    echo [SUCCESS] Main cron job completed >> "%CRON_LOG%"
    echo [%time%] Main cron job completed
)

echo.
echo ------------------------------------------------------------

REM 2. Update Expired Sessions (Auto Logout)
echo [%time%] Updating expired sessions...
echo [%date% %time%] Running UpdateExpiredSessions.php >> "%CRON_LOG%"
%PHP_EXE% -f cron\UpdateExpiredSessions.php >> "%CRON_LOG%" 2>&1
if errorlevel 1 (
    echo [ERROR] Session cleanup failed! >> "%CRON_LOG%"
    echo [ERROR] Session cleanup failed!
) else (
    echo [SUCCESS] Session cleanup completed >> "%CRON_LOG%"
    echo [%time%] Session cleanup completed
)

echo.
echo ------------------------------------------------------------

REM 3. Mail Scanner (if enabled)
echo [%time%] Running mail scanner...
echo [%date% %time%] Running MailScanner service >> "%CRON_LOG%"
%PHP_EXE% -f vtigercron.php service=MailScanner >> "%CRON_LOG%" 2>&1
if errorlevel 1 (
    echo [WARNING] Mail scanner failed or not configured >> "%CRON_LOG%"
    echo [%time%] Mail scanner completed (may be disabled)
) else (
    echo [SUCCESS] Mail scanner completed >> "%CRON_LOG%"
    echo [%time%] Mail scanner completed
)

echo.
echo ------------------------------------------------------------

REM 4. Send Reminders
echo [%time%] Sending reminders...
echo [%date% %time%] Running SendReminder service >> "%CRON_LOG%"
%PHP_EXE% -f vtigercron.php service=SendReminder >> "%CRON_LOG%" 2>&1
if errorlevel 1 (
    echo [WARNING] Send reminder failed >> "%CRON_LOG%"
    echo [%time%] Send reminder completed
) else (
    echo [SUCCESS] Send reminder completed >> "%CRON_LOG%"
    echo [%time%] Send reminder completed
)

echo.
echo ------------------------------------------------------------

REM 5. Workflow Tasks
echo [%time%] Running workflow tasks...
echo [%date% %time%] Running Workflow service >> "%CRON_LOG%"
%PHP_EXE% -f vtigercron.php service=Workflow >> "%CRON_LOG%" 2>&1
if errorlevel 1 (
    echo [WARNING] Workflow tasks failed >> "%CRON_LOG%"
    echo [%time%] Workflow tasks completed
) else (
    echo [SUCCESS] Workflow tasks completed >> "%CRON_LOG%"
    echo [%time%] Workflow tasks completed
)

echo.
echo ------------------------------------------------------------

REM 6. Recurring Invoices
echo [%time%] Processing recurring invoices...
echo [%date% %time%] Running RecurringInvoice service >> "%CRON_LOG%"
%PHP_EXE% -f vtigercron.php service=RecurringInvoice >> "%CRON_LOG%" 2>&1
if errorlevel 1 (
    echo [WARNING] Recurring invoices failed >> "%CRON_LOG%"
    echo [%time%] Recurring invoices completed
) else (
    echo [SUCCESS] Recurring invoices completed >> "%CRON_LOG%"
    echo [%time%] Recurring invoices completed
)

echo.
echo ------------------------------------------------------------

REM 7. Scheduled Reports
echo [%time%] Running scheduled reports...
echo [%date% %time%] Running ScheduleReports service >> "%CRON_LOG%"
%PHP_EXE% -f vtigercron.php service=ScheduleReports >> "%CRON_LOG%" 2>&1
if errorlevel 1 (
    echo [WARNING] Scheduled reports failed >> "%CRON_LOG%"
    echo [%time%] Scheduled reports completed
) else (
    echo [SUCCESS] Scheduled reports completed >> "%CRON_LOG%"
    echo [%time%] Scheduled reports completed
)

echo.
echo ------------------------------------------------------------

REM 8. Scheduled Imports
echo [%time%] Running scheduled imports...
echo [%date% %time%] Running ScheduledImport service >> "%CRON_LOG%"
%PHP_EXE% -f vtigercron.php service=ScheduledImport >> "%CRON_LOG%" 2>&1
if errorlevel 1 (
    echo [WARNING] Scheduled imports failed >> "%CRON_LOG%"
    echo [%time%] Scheduled imports completed
) else (
    echo [SUCCESS] Scheduled imports completed >> "%CRON_LOG%"
    echo [%time%] Scheduled imports completed
)

echo.
echo ============================================================
echo [%time%] All cron jobs completed!
echo ============================================================
echo [%date% %time%] All cron jobs completed successfully >> "%CRON_LOG%"
echo ============================================================ >> "%CRON_LOG%"
echo. >> "%CRON_LOG%"

REM Optional: Keep window open for manual runs (comment out for scheduled tasks)
REM pause
