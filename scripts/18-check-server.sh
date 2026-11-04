#!/bin/bash

# Audit essential system configurations: active hostname, IPv4 interface addresses, 
# DNS nameservers, NTP clock synchronization status, filesystem and physical 
# storage mapping, and OS release/kernel details.

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root or with sudo."
    exit 1
fi

echo " --- HOSTNAME: $(hostname)"
echo " --- IP ADDRESS & INTERFACE"
ip -br -4 address show | awk '$3 !~ /127.0.0.1/ {printf "  Interface: %-10s Status: %-6s IP: %s\n", $1, $2, $3}'
echo ""

echo " --- DNS RESOLUTION"
echo "Configured Nameservers in /etc/resolv.conf:"
grep -E '^nameserver' /etc/resolv.conf | awk '{print " - " $2}' || echo " WARNING: No explicit nameservers found."
echo ""

echo " --- NTP & TIME SYNCHRONIZATION"
if command -v timedatectl &>/dev/null; then
    timedatectl status | grep -E "Local time|Universal time|RTC time|Time zone|System clock synchronized|NTP service" | sed 's/^/  /'
else   
    echo " timedatectl missing, System Time: $(date) "
fi
echo ""

echo " --- STORAGE & FILESYSTEM"
echo "Active Filesystems Usage:"
df -h -x tmpfs -x devtmpfs | awk 'NR==1 || $5+0 > 0' | sed 's/^/  /'
echo ""
echo "Physical Drives:"
lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINT | grep -v "loop" | sed 's/^/  /'
echo ""

echo " --- KERNEL & OPERATING SYSTEM"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  OS Distribution:   ${PRETTY_NAME:-Unknown}"
fi
echo "Kernel Version:    $(uname -r)"

echo ""
echo "[INFO] Script execution completed."