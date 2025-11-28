#!/bin/bash
# Auto Setup Script for VtigerCRM Cron Jobs on Linux

echo "============================================================"
echo "VtigerCRM Cron Setup for Linux"
echo "============================================================"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRON_SCRIPT="$SCRIPT_DIR/cron.sh"
VTIGER_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$VTIGER_ROOT/logs"

echo ""
echo "Directories:"
echo "  - Script Dir: $SCRIPT_DIR"
echo "  - Vtiger Root: $VTIGER_ROOT"
echo "  - Log Dir: $LOG_DIR"
echo ""

# Step 1: Check if script exists
if [ ! -f "$CRON_SCRIPT" ]; then
    echo "[ERROR] cron.sh not found at: $CRON_SCRIPT"
    exit 1
fi
echo "[OK] Found cron.sh"

# Step 2: Convert line endings
echo "[STEP 1] Converting line endings..."
if command -v dos2unix >/dev/null 2>&1; then
    dos2unix "$CRON_SCRIPT" 2>/dev/null
    echo "[OK] Used dos2unix"
else
    sed -i 's/\r$//' "$CRON_SCRIPT"
    echo "[OK] Used sed"
fi

# Step 3: Set permissions
echo "[STEP 2] Setting permissions..."
chmod +x "$CRON_SCRIPT"
echo "[OK] Set execute permission on cron.sh"

# Step 4: Create and set log directory
echo "[STEP 3] Setting up log directory..."
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
echo "[OK] Log directory created: $LOG_DIR"

# Step 5: Check PHP
echo "[STEP 4] Checking PHP..."
if command -v php >/dev/null 2>&1; then
    PHP_VERSION=$(php -v | head -n 1)
    echo "[OK] PHP found: $PHP_VERSION"
else
    echo "[ERROR] PHP not found! Please install PHP first."
    exit 1
fi

# Step 6: Test run
echo "[STEP 5] Testing cron script..."
cd "$VTIGER_ROOT"
bash "$CRON_SCRIPT"
if [ $? -eq 0 ]; then
    echo "[OK] Test run completed"
else
    echo "[WARNING] Test run had some issues, but continuing..."
fi

# Step 7: Setup crontab
echo "[STEP 6] Setting up crontab..."
CRON_ENTRY="*/15 * * * * /bin/bash $CRON_SCRIPT >> $LOG_DIR/cron_output.log 2>&1"

# Check if entry already exists
if crontab -l 2>/dev/null | grep -q "$CRON_SCRIPT"; then
    echo "[INFO] Cron entry already exists. Updating..."
    (crontab -l 2>/dev/null | grep -v "$CRON_SCRIPT"; echo "$CRON_ENTRY") | crontab -
else
    echo "[INFO] Adding new cron entry..."
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
fi

echo "[OK] Crontab configured to run every 15 minutes"

# Step 8: Verify
echo ""
echo "============================================================"
echo "Setup Complete!"
echo "============================================================"
echo ""
echo "Cron Configuration:"
crontab -l | grep "$CRON_SCRIPT"
echo ""
echo "Log Files:"
echo "  - Cron execution log: $LOG_DIR/cron_all.log"
echo "  - Cron output log: $LOG_DIR/cron_output.log"
echo ""
echo "To view logs in real-time:"
echo "  tail -f $LOG_DIR/cron_all.log"
echo ""
echo "To manually run cron:"
echo "  bash $CRON_SCRIPT"
echo ""
echo "To edit crontab:"
echo "  crontab -e"
echo ""
echo "============================================================"
