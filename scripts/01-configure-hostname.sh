#!/bin/bash

# Enforce a static hostname change and update the /etc/hosts mapping accordingly.
# Requires root privileges to modify system hostname and host files.
# TO USE : ./01-configure-hostname.sh <Server-Name> <IP-Address>

set -euo pipefail

NEW_HOSTNAME="$1"
IP_ADDRESS="$2"
CONFIG_FILE="/etc/hosts"

echo "Checking if script is executed by root"
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root or with sudo." >&2
    exit 1
fi

echo "Updating hostname to: $NEW_HOSTNAME..."

echo "Set the hostname permanently"
hostnamectl set-hostname "$NEW_HOSTNAME"

echo "Backup existing file"
cp "$CONFIG_FILE" "${CONFIG_FILE}.bkp"

echo "Generate the new /etc/hosts file"
cat << EOF > "$CONFIG_FILE"
# Loopback entries; do not change.
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# Static IP mapping for this host
$IP_ADDRESS $NEW_HOSTNAME
EOF

echo "SUCCESS: Hostname updated to $NEW_HOSTNAME"
echo ""
echo "[INFO] Script execution completed."
