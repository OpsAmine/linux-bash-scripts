#!/bin/bash

# Provision a local user with a home directory, set a default password, 
# and grant administrative privileges via sudo or wheel based on the OS.
# TO USE : ./03-configure-users.sh <USERNAME>

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <username>"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root or with sudo."
    exit 1
fi

USERNAME="$1"

echo "Creating the user with a default home directory"
useradd -m "$USERNAME"

passwd "$USERNAME"

. /etc/os-release
OS_ID="${ID,,}"

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    usermod -aG sudo "$USERNAME"
elif [[ "$OS_ID" == "rhel" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" || "$OS_ID" == "centos" ]]; then
    usermod -aG wheel "$USERNAME"
else
    echo "ERROR: Unsupported OS family ($OS_ID)."
    exit 1
fi

echo ""
echo "[INFO] Script execution completed."
