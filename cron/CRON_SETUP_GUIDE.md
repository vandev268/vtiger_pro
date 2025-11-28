# VtigerCRM - Comprehensive Cron Job Setup Guide

## Overview
This guide helps you set up a comprehensive cron job that runs all VtigerCRM scheduled tasks automatically.

## Files Created
- **run_all_crons.bat** - Windows batch file for running all cron jobs
- **run_all_crons.sh** - Linux/Unix shell script for running all cron jobs

## What Gets Run

The comprehensive cron script executes the following tasks in sequence:

1. **Main VtigerCRM Cron** - Core system cron jobs
2. **Update Expired Sessions** - Auto logout inactive users
3. **Mail Scanner** - Scan and import emails
4. **Send Reminders** - Send task/event reminders
5. **Workflow Tasks** - Execute scheduled workflows
6. **Recurring Invoices** - Generate recurring invoices
7. **Scheduled Reports** - Send scheduled reports
8. **Scheduled Imports** - Process scheduled data imports

## Windows Setup (Task Scheduler)

### Option 1: Automatic Setup (Recommended)

1. Open Command Prompt as Administrator
2. Run the following command:

```batch
schtasks /create /tn "VtigerCRM-AllCrons" /tr "C:\xampp\htdocs\cusc\cron\run_all_crons.bat" /sc minute /mo 15 /ru SYSTEM
```

This creates a scheduled task that runs every 15 minutes.

### Option 2: Manual Setup via Task Scheduler GUI

1. Press `Win + R`, type `taskschd.msc`, press Enter
2. Click **Action** → **Create Basic Task**
3. Name: `VtigerCRM-AllCrons`
4. Trigger: **Daily** → **Recur every: 1 days**
5. Click **Repeat task every**: `15 minutes`
6. Duration: `Indefinitely`
7. Action: **Start a program**
8. Program: `C:\xampp\htdocs\cusc\cron\run_all_crons.bat`
9. Click **Finish**

### Verify Windows Task

```batch
schtasks /query /tn "VtigerCRM-AllCrons"
```

### Delete Windows Task (if needed)

```batch
schtasks /delete /tn "VtigerCRM-AllCrons" /f
```

## Linux/Unix Setup (Crontab)

### 1. Make Script Executable

```bash
cd /path/to/vtiger/cron
chmod +x run_all_crons.sh
```

### 2. Edit Crontab

```bash
crontab -e
```

### 3. Add Cron Entry

For every 15 minutes:
```cron
*/15 * * * * /path/to/vtiger/cron/run_all_crons.sh >/dev/null 2>&1
```

For every 30 minutes:
```cron
*/30 * * * * /path/to/vtiger/cron/run_all_crons.sh >/dev/null 2>&1
```

For every hour:
```cron
0 * * * * /path/to/vtiger/cron/run_all_crons.sh >/dev/null 2>&1
```

### 4. Save and Exit
- Press `Esc`, type `:wq`, press Enter (for vi/vim)
- Or `Ctrl+X`, `Y`, Enter (for nano)

### Verify Crontab

```bash
crontab -l
```

## Recommended Frequency

- **Small deployments** (< 50 users): Every 30 minutes
- **Medium deployments** (50-200 users): Every 15 minutes
- **Large deployments** (> 200 users): Every 10-15 minutes

## Log Files

All cron execution logs are stored in:
```
logs/cron_all.log
```

### View Recent Logs (Windows)

```batch
type logs\cron_all.log
```

### View Recent Logs (Linux)

```bash
tail -f logs/cron_all.log
```

## Manual Testing

### Windows

1. Open Command Prompt
2. Navigate to VtigerCRM directory:
```batch
cd C:\xampp\htdocs\cusc
```
3. Run the cron script:
```batch
cron\run_all_crons.bat
```

### Linux

```bash
cd /path/to/vtiger
./cron/run_all_crons.sh
```

## Troubleshooting

### Check if Cron is Running

**Windows:**
```batch
schtasks /query /fo LIST /v | findstr "VtigerCRM"
```

**Linux:**
```bash
ps aux | grep run_all_crons
```

### Common Issues

1. **Permission Denied (Linux)**
   ```bash
   chmod +x cron/run_all_crons.sh
   ```

2. **PHP Not Found**
   - Windows: Update `PHP_EXE` path in `run_all_crons.bat`
   - Linux: Update `USE_PHP` in `run_all_crons.sh`

3. **Path Issues**
   - Ensure all paths in the script match your installation
   - Check `VTIGERCRM_ROOTDIR` variable

4. **Log File Permissions**
   ```bash
   chmod 755 logs
   chmod 644 logs/cron_all.log
   ```

## Individual Cron Jobs

If you need to run specific cron jobs separately, you can still use:

- `vtigercron.bat` / `vtigercron.sh` - Main VtigerCRM cron
- `UpdateExpiredSessions.bat` / `UpdateExpiredSessions.php` - Session cleanup only
- `vtigercron.php?service=ServiceName` - Specific service

## Important Notes

1. **Do not run multiple instances simultaneously** - The script handles this automatically
2. **Monitor logs regularly** - Check `logs/cron_all.log` for errors
3. **Adjust frequency based on load** - More users = more frequent runs
4. **Test before scheduling** - Always test manually first
5. **Backup before changes** - Backup your crontab/scheduled tasks

## Support

For VtigerCRM cron issues, check:
- VtigerCRM Forums: https://discussions.vtiger.com/
- Documentation: https://wiki.vtiger.com/
- Log files in the `logs/` directory

## Version
Created: November 2025
Compatible with: VtigerCRM 7.x and later
