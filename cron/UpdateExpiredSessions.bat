@echo off
REM Auto update logout time for expired sessions
REM Run this every 5-10 minutes via Task Scheduler

cd /d "C:\xampp\htdocs\cusc"
C:\xampp\php\php.exe cron\UpdateExpiredSessions.php >> logs\session_cleanup.log 2>&1
