#!/bin/bash

# Run a comprehensive system performance check (CPU utilization, top CPU-consuming 
# processes, memory breakdown, filesystem storage, hardware block device mapping, 
# and the largest subdirectories in /var and /data) and print a formatted summary.
# Description : Script to check ressources usage, includes :
#               - CPU Usage
#               - Top 3 Processes using CPU
#               - RAM Usage
#               - Filesystem Storage Usage
#               - Hardware Disk Mapping
#               - Largest DIrectories in /var et /data (only top 5 listed)
# NOTE: Script only run once.

set -euo pipefail

echo "      SYSTEM PERFORMANCE (CPU, MEM, STORAGE)      "
echo " ************************************************ "
echo "Time & Date: $(date)"
echo "Executed by: $(whoami)"
echo ""

echo "----- CPU USAGE -----"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo "Current CPU Utilization: $(CPU_USAGE)%"
echo ""

echo "----- Top 3 Processes using CPU -----"
ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -n 4 | awk '
    NR==1 {printf "  %-8s %-30s %-6s\n", "PID", "COMMAND", "%CPU"}
    NR>1  {printf "  %-8s %-30s %-6s%%\n", $1, substr($3,1,30), $4}
'
echo ""

echo "----- RAM Usage -----"
free -h | awk '
    NR==1 {print "      Total       Used        Free        Available"}
    NR==2 {printf "Mem:  %-11s %-11s %-11s %-11s\n", $2, $3, $4, $7}
'
echo ""

echo "----- Filesystem Storage Usage -----"
df -h -x tmpfs -x devtmpfs | awk 'NR==1 || $5+0 > 0'
echo ""

echo "----- Hardware Disk Mapping (/dev/sdX, nvme) -----"
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep -v "loop"
echo ""


echo "----- Top 5 Largest Directories in /var and /data -----"
echo "Searching /var..."
du -ah /var 2>/dev/null | sort -rh | head -n 5 || echo "Could not read /var"
echo ""

echo "Searching /data..."
du -ah /data 2>/dev/null | sort -rh | head -n 5 || echo "Could not read /data"

echo ""
echo "[INFO] Script execution completed."