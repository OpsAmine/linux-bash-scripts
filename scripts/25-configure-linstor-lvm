#!/bin/bash

# Prepares raw block storage for LINSTOR/DRBD by setting up an LVM volume group.
# Run this on hosts destined to be storage satellites before initiating the cluster.

set -euo pipefail

TARGET_DISK="/dev/sdX"
VG_NAME="linstor_vg"

echo ""
echo "Preparing $TARGET_DISK for LINSTOR"

if [ ! -b "$TARGET_DISK" ]; then
    echo "ERROR: Target disk $TARGET_DISK does not exist." >&2
    exit 1
fi

echo ""
echo "Verifying if disk or partition already mounted..."

if lsblk -nr -o MOUNTPOINT "$TARGET_DISK" | grep -q '[^[:space:]]'; then
    echo "ERROR: $TARGET_DISK or one of its partitions is mounted." >&2
    exit 1
fi

echo ""
echo "Verifying if $VG_NAME already exists..."

if vgs --noheadings -o vg_name 2>/dev/null | grep -qw "$VG_NAME"; then
    echo "ERROR: Volume group $VG_NAME already exists." >&2
    exit 1
else
    echo "Creating volume group $VG_NAME using $TARGET_DISK"
    vgcreate "$VG_NAME" "$TARGET_DISK"
    vgs
fi

echo ""
echo "[INFO] Script execution completed."
