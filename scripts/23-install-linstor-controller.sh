#!/bin/bash

# This script sets up the DRBD repository and installs the LINSTOR 
# controller and client toolchain on Ubuntu.

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

# Fixed: Properly split package names into separate array elements
PACKAGES=("drbd-utils" "drbd-dkms" "linstor-controller" "linstor-satellite" "linstor-client")

for pkg in "${PACKAGES[@]}"; do
    echo "Installing $pkg..."
    apt-get install -y "$pkg"
    
    case "$pkg" in
        linstor-controller)
            systemctl enable --now linstor-controller
            if systemctl is-active --quiet linstor-controller; then
                echo "LINSTOR-CONTROLLER is installed and enabled."
            else
                echo "ERROR: linstor-controller failed to start."
                exit 1
            fi
            ;;
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
