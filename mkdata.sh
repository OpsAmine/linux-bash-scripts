#!/bin/bash

#==============================================================================
# Script Name : mkdata.sh
# Description : Automates the preparation of a dedicated data disk using
#               GPT partitioning, LVM and the XFS filesystem, then mounts it
#               persistently on /data
#------------------------------------------------------------------------------
# What it does:
#   1. Verifies it is run as root, the target disk exists, the required tools
#      are installed, the disk is not mounted and the VG does not already exist
#   2. Asks for explicit confirmation before destroying any data
#   3. Wipes old signatures and creates a GPT partition table
#   4. Creates a single partition spanning the whole disk, flagged for LVM
#   5. Creates the physical volume (PV), volume group (VG) and logical
#      volume (LV) using 100% of the free space
#   6. Formats the logical volume as XFS
#   7. Creates the mount point and adds a UUID-based entry to /etc/fstab
#      (a timestamped backup of /etc/fstab is made first)
#   8. Mounts the volume and verifies the result
#
# Default configuration (edit the variables below to change them):
#   Target disk  : /dev/sdb
#   Partition    : /dev/sdb1
#   Volume group : vg_data
#   Logical vol. : lv_data
#   Mount point  : /data
#   Filesystem   : xfs
#
# Requirements:
#   - Root privileges (run as root or with sudo)
#   - Packages: parted, lvm2, xfsprogs, util-linux
#   - A dedicated, unused disk (ALL DATA ON IT WILL BE DESTROYED)
#
# Usage:
#   sudo ./mkdata.sh
#   (make it executable first with: chmod +x mkdata.sh)
#
# Notes:
#   - For NVMe disks, change PARTITION to "${TARGET_DISK}p1"
#   - The script stops on the first error (set -euo pipefail)
#   - The fstab entry uses the "nofail" option so a missing disk does not
#     block the system from booting
#
# Exit codes:
#   0 : Success
#   1 : Pre-flight check failed, user aborted, or a step failed
#==============================================================================

set -euo pipefail

TARGET_DISK="/dev/sdb"
PARTITION="${TARGET_DISK}1"
MOUNT_POINT="/data"
VG_NAME="vg_data"
LV_NAME="lv_data"
TARGET="/dev/$VG_NAME/$LV_NAME"

echo "Verifying if script is run as root or sudo..."
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run script as root or using sudo." >&2
    exit 1
fi

echo "Verifying existance of target disk..."
if [ ! -b "$TARGET_DISK" ]; then
    echo "ERROR: Target disk $TARGET_DISK does not exist." >&2
    exit 1
fi

echo "Verifying existance of necessary packages..."
for cmd in parted pvcreate vgcreate lvcreate mkfs.xfs blkid partprobe wipefs; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command '$cmd' not found (install lvm2, parted, xfsprogs)." >&2
        exit 1
    else 
        echo "SUCCESS: Necessary packages exist. Proceeding..."
    fi
done

echo "Verifying if disk or partition already mounted..."
if lsblk -nr -o MOUNTPOINT "$TARGET_DISK" | grep -q '[^[:space:]]'; then
    echo "ERROR: $TARGET_DISK or one of its partitions is mounted." >&2
    exit 1
fi

echo "Verifying if $VG_NAME areadt exists..."
if vgs --noheadings -o vg_name 2>/dev/null | grep -qw "$VG_NAME"; then
    echo "ERROR: Volume group $VG_NAME already exists." >&2
    exit 1
fi

echo "[ WARNING: All data on $TARGET_DISK will be destroyed. ]"
read -r -p "Type 'yes' to continue: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi


echo "Running Partitioning Setup..."

echo "Step 1: Wiping old signatures and creating GPT partition table"
wipefs -a "$TARGET_DISK"
parted --script "$TARGET_DISK" mklabel gpt

echo "Step 2: Creating primary partition (flagged for LVM)"
parted --script "$TARGET_DISK" mkpart primary 0% 100%
parted --script "$TARGET_DISK" set 1 lvm on
partprobe "$TARGET_DISK"

if [ ! -b "$PARTITION" ]; then
    echo "ERROR: Partition $PARTITION was not created." >&2
    exit 1
fi

echo "Step 3: Creating physical volume"
pvcreate "$PARTITION"
pvs

echo "Step 4: Creating volume group $VG_NAME"
vgcreate "$VG_NAME" "$PARTITION"
vgs

echo "Step 5: Creating logical volume $LV_NAME"
lvcreate -l 100%FREE -n "$LV_NAME" "$VG_NAME"
lvs


# Formatting

echo "Running Formatting Setup..."

echo "Step 6: Formatting $TARGET as xfs"
mkfs.xfs -f "$TARGET"

# Mounting 

echo "Mounting $MOUNT_POINT and persisting in /etc/fstab ..."

echo "Step 7: Creating mount directory at $MOUNT_POINT"
mkdir -p "$MOUNT_POINT"

echo "Step 8: Adding fstab entry"
UUID=$(blkid -o value -s UUID "$TARGET")
if [ -z "$UUID" ]; then
    echo "ERROR: Could not read UUID of $TARGET." >&2
    exit 1
fi

if grep -q "$UUID" /etc/fstab; then
    echo "fstab entry for $UUID already exists, skipping."
else
    cp /etc/fstab "/etc/fstab.bak.$(date +%F-%H%M%S)"
    echo "UUID=$UUID $MOUNT_POINT  xfs  defaults  0 2" >> /etc/fstab
fi

echo "Running Mounting Setup..."
echo "Step 9: Mounting and verifying"
systemctl daemon-reload 2>/dev/null || true
mount -a
if ! findmnt -n "$MOUNT_POINT" >/dev/null; then
    echo "ERROR: $MOUNT_POINT failed to mount." >&2
    exit 1
fi

df -hT "$MOUNT_POINT"
echo "SUCCESS: $TARGET mounted on $MOUNT_POINT (UUID=$UUID)."
