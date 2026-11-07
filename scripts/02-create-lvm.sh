#!/bin/bash

# Automate raw block storage provisioning: create GPT partition tables, 
# configure LVM volumes, format with XFS, and bind persistently to /data.
# TO USE: ./02-create-lvm.sh <Disk_Name> <Mount_Point> <Volume_Group_Name> <Logical_Volume_Name>

set -euo pipefail

TARGET_DISK="$1"
PARTITION="${TARGET_DISK}1"
MOUNT_POINT="$2"
VG_NAME="$3"
LV_NAME="$4"
TARGET="/dev/$VG_NAME/$LV_NAME"

# Verify if script is run as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run script as root or using sudo." >&2
    exit 1
fi

echo "Verifying existence of target disk..."

if [ ! -b "$TARGET_DISK" ]; then
    echo "ERROR: Target disk $TARGET_DISK does not exist." >&2
    exit 1
fi

echo "Verifying existance of necessary packages..."

for cmd in parted pvcreate vgcreate lvcreate mkfs.xfs blkid partprobe; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command '$cmd' not found." >&2
        
        case "$cmd" in
            pvcreate|vgcreate|lvcreate)
                pkg="lvm2"
                ;;
            parted)
                pkg="parted"
                ;;
            mkfs.xfs)
                pkg="xfsprogs"
                ;;
            blkid|partprobe)
                pkg="util-linux"
                ;;
            *)
                pkg=""
                ;;
        esac

        if [ -n "$pkg" ]; then
            echo "Attempting to install missing package: $pkg"
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y "$pkg"
            elif command -v apt >/dev/null 2>&1; then
                apt update -y
                apt install -y "$pkg"
            else
                echo "ERROR: No supported package manager found to install $pkg" >&2
            fi
        else
            echo "ERROR: Manual installation required for command '$cmd'." >&2
        fi
    fi
done

echo "Verifying if disk or partition already mounted..."

if lsblk -nr -o MOUNTPOINT "$TARGET_DISK" | grep -q '[^[:space:]]'; then
    echo "ERROR: $TARGET_DISK or one of its partitions is mounted." >&2
    exit 1
fi

echo "Verifying if $VG_NAME already exists..."

if vgs --noheadings -o vg_name 2>/dev/null | grep -qw "$VG_NAME"; then
    echo "ERROR: Volume group $VG_NAME already exists." >&2
    exit 1
fi

echo "Verifying if $LV_NAME already exists..."

if vgs --noheadings -o lv_name 2>/dev/null | grep -qw "$LV_NAME"; then
    echo "ERROR: Logical volume $LV_NAME already exists." >&2
    exit 1
fi

echo "Running Partitioning Setup..."

echo "Step 1: Creating GPT partition table"

parted --script "$TARGET_DISK" mklabel gpt

echo "Step 2: Creating primary partition (flagged for LVM)"

parted --script "$TARGET_DISK" mkpart primary 0% 100%
parted --script "$TARGET_DISK" set 1 lvm on
partprobe "$TARGET_DISK"

if [ ! -b "$PARTITION" ]; then
    echo "ERROR: Partition $PARTITION was not created." >&2
    exit 1
fi

echo "Step 3: Creating physical volume using $PARTITION"

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

df -h "$MOUNT_POINT"
echo "SUCCESS: $TARGET mounted on $MOUNT_POINT (UUID=$UUID)."

echo "[INFO] Script execution completed."
