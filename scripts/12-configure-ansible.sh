#!/bin/bash

# Generate an Ed25519 SSH keypair for a local service user, set strict 
# file permissions on the .ssh directory, and securely copy the public 
# key to a remote server using ssh-copy-id.

set -euo pipefail

# Configuration
SSH_USER="vortex"
SERVER_IP="192.168.1.10"
KEY_PATH="/home/${SSH_USER}/.ssh/id_ed25519"

# Check root privileges
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run this script as root or with sudo."
    exit 1
fi

# Check that local user exists
if ! id "$SSH_USER" &>/dev/null; then
    echo "ERROR: User $SSH_USER does not exist."
    exit 1
fi

SSH_DIR="$(dirname "$KEY_PATH")"

echo "Preparing SSH directory..."

install -d -m 700 -o "$SSH_USER" -g "$SSH_USER" "$SSH_DIR"

echo "Generating SSH key..."

if [[ ! -f "$KEY_PATH" ]]; then
    sudo -u "$SSH_USER" ssh-keygen \
        -t ed25519 \
        -N "" \
        -f "$KEY_PATH" \
        -C "${SSH_USER}@$(hostname)"
else
    echo "SSH key already exists. Skipping generation."
fi

# Validate public key
if [[ ! -f "${KEY_PATH}.pub" ]]; then
    echo "ERROR: Public key not found: ${KEY_PATH}.pub"
    exit 1
fi

echo "Copying public key to remote server..."

sudo -u "$SSH_USER" ssh-copy-id \
    -i "${KEY_PATH}.pub" \
    -o StrictHostKeyChecking=accept-new \
    "${SSH_USER}@${SERVER_IP}"

echo "SUCCESS: SSH key deployment completed."

echo ""
echo "[INFO] Script execution completed."