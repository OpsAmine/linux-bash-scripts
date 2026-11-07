#!/bin/bash

# Validates required LINSTOR packages, generates the Docker volume plugin configuration,
# and installs the Linbit Docker volume plugin.

set -euo pipefail

LINSTOR_PATH="/etc/linstor"
VOLUME_FILE="docker-volume.conf"
DOCKER_PLUGIN="linbit/linbit-docker-volume:latest"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root, or with sudo."
    exit 1
fi

PACKAGES=("drbd-utils" "drbd-dkms" "linstor-satellite")

STORAGE_POOL="myStorage"
DEFAULT_FS="xfs"
DEFAULT_SIZE="1G"
DEFAULT_REPLICAS_NUM="3"

CONTROLLER_IP="X.X.X.X"
CONTROLLER="linstor://$CONTROLLER_IP"

echo "Verifying required packages"

for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "ERROR: Package '$pkg' is not installed. Please install it first."
        exit 1
    fi
done

echo "Creating Docker's LINSTOR configuration"

if [ ! -d "$LINSTOR_PATH" ]; then
    echo "Creating directory: $LINSTOR_PATH"
    mkdir -p "$LINSTOR_PATH"
fi

cat << EOF > "$LINSTOR_PATH/$VOLUME_FILE"
[global]
storagepool = $STORAGE_POOL
fs = $DEFAULT_FS
size = $DEFAULT_SIZE
replicas = $DEFAULT_REPLICAS_NUM
controllers = $CONTROLLER
EOF

echo "Installing Docker Plugin"

if command -v docker >/dev/null 2>&1; then
    if docker plugin inspect "$DOCKER_PLUGIN" >/dev/null 2>&1; then
        echo "Docker plugin '$DOCKER_PLUGIN' is already installed."
    else
        docker plugin install "$DOCKER_PLUGIN" --grant-all-permissions
    fi
else
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

echo ""
echo "[INFO] Script execution completed successfully."
