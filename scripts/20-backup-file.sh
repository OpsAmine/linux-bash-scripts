#!/bin/bash

# Back up a specified file or directory path into a dated compressed 
# tarball archive within a target backup destination directory, enforcing 
# root privileges and verifying source existence.
# TO USE : 1. Directory : sudo ./backup.sh /etc/docker /data/backups
#          2. File: ./backup.sh /etc/fstab  /data/backups

set -e

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root or with sudo."
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source> <backup_directory>"
    exit 1
fi

SOURCE="$1"
BACKUP_DIR="$2"
DATE=$(date -I)
NAME=$(basename "$SOURCE")

if [ ! -e "$SOURCE" ]; then
    echo "ERROR: Source does not exist."
    exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "Backing up $SOURCE..."

tar -czf "$BACKUP_DIR/${NAME}-${DATE}.tar.gz" -C "$(dirname "$SOURCE")" "$NAME"

echo "Backup: $BACKUP_DIR/${NAME}-${DATE}.tar.gz"

echo ""
echo "[INFO] Script execution completed."