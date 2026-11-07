#!/bin/bash

# Script to install linstor and drbd9 on ubuntu (for linstor satellite)

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root, or with sudo."
    exit 1
fi

LINBIT_DRBD_REPO_URL="ppa:linbit/linbit-drbd9-stack"

if command -v apt-get >/dev/null 2>&1; then
    add-apt-repository -y "$LINBIT_DRBD_REPO_URL"
    apt-get update
else
    echo "ERROR: Unsupported package manager."
    exit 1
fi

PACKAGES=("drbd-utils" "drbd-dkms" "linstor-satellite")

for pkg in "${PACKAGES[@]}"; do
    echo "Installing $pkg..."
    apt-get install -y "$pkg"
    
    case "$pkg" in
        linstor-satellite)
            systemctl enable --now linstor-satellite
            if systemctl is-active --quiet linstor-satellite; then
                echo "LINSTOR-SATELLITE is installed and enabled."
            else
                echo "ERROR: linstor-satellite failed to start."
                exit 1
            fi
            ;;
        drbd-utils|drbd-dkms)
            if command -v drbdadm >/dev/null 2>&1; then
                echo "DRBD IS INSTALLED: $(drbdadm --version | head -n 1)"
            else
                echo "ERROR: DRBD not installed correctly."
                exit 1
            fi 
            ;;
    esac
done

echo ""
echo "[INFO] Script execution completed."
