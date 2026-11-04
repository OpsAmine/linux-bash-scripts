#!/bin/bash

# Back up critical system configuration files (/etc/hostname, hosts, fstab, 
# ssh, chrony, docker daemon.json) and active firewall rules (ufw or firewalld) 
# into a dated directory, compress them into a tarball, and clean up temporary files.

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root, or with sudo."
    exit 1
fi

BACKUP_DIR="/data/backups/configs"
DATE=$(date -I)
DEST="$BACKUP_DIR/$DATE"

echo "Starting Backup File"

mkdir -p "$DEST"

# Backup System Configs
cp -a /etc/hostname "$DEST/"
cp -a /etc/hosts "$DEST/"
cp -a /etc/fstab "$DEST/"
cp -a /etc/ssh "$DEST/"
cp -a /etc/chrony.conf "$DEST/" 2>/dev/null || true

# Backup Docker Config
if [ -f /etc/docker/daemon.json ]; then
    cp -a /etc/docker/daemon.json "$DEST/"
fi

# Ubuntu: Backup firewall config
if command -v ufw &>/dev/null; then
    ufw status numbered > "$DEST/ufw-status.txt"
fi

# RHEL: Backup firewall config
if command -v firewall-cmd &>/dev/null; then
    firewall-cmd --list-all-zones > "$DEST/firewalld-status.txt"
fi

# Archive backup
tar -czf "$BACKUP_DIR/configs-$DATE.tar.gz" -C "$BACKUP_DIR" "$DATE"

rm -rf "$DEST"

echo "Backup completed successfully."
echo "Location: $BACKUP_DIR/configs-$DATE.tar.gz"

echo ""
echo "[INFO] Script execution completed."