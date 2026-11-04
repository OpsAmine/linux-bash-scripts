#!/bin/bash

# Prevent automatic kernel upgrades on Debian/Ubuntu systems by holding 
# generic kernel packages (linux-generic, linux-image-generic, linux-headers-generic) 
# via dpkg/apt-mark to stabilize production environments.

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root, or with sudo."
    exit 1
fi

echo "Holding kernel packages..."

for pkg in linux-generic linux-image-generic linux-headers-generic; do
    if dpkg -s "$pkg" &>/dev/null; then
        apt-mark hold "$pkg"
    fi
done

echo "Current kernel: $(uname -r)"
echo "Held packages:"
apt-mark showhold

echo ""
echo "[INFO] Script execution completed."
