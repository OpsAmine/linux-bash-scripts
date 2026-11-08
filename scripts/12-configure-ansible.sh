#!/bin/bash

# Generate an Ed25519 SSH keypair for a local service user, set strict 
# file permissions on the .ssh directory, and securely copy the public 
# key to a remote server using ssh-copy-id.
# to execute, run: ./12-configure-ansible.sh <user> <host-ip>

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <user> <host-ip>"
    exit 1
fi

SSH_USER="$1"
SERVER_IP="$2"
KEY_PATH="/home/${SSH_USER}/.ssh/id_ed25519"

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run this script as root or with sudo."
    exit 1
fi

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

echo "Running Ansible Test Ping"

INVENTORY="$(mktemp)"
trap 'rm -f "$INVENTORY"' EXIT
chmod 644 "$INVENTORY"

cat > "$INVENTORY" <<EOF
[servers]
${SERVER_IP} ansible_user=${SSH_USER} ansible_ssh_private_key_file=${KEY_PATH}
EOF

echo "Running: ansible all -i inventory -m ping"
sudo -u "$SSH_USER" ansible all -i "$INVENTORY" -m ping

echo "SUCCESS: Ansible ping test passed."

echo ""
echo "[INFO] Script execution completed."
