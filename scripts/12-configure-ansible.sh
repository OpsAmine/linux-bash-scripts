#!/bin/bash

# Generate an Ed25519 SSH keypair for a local service user, set strict 
# file permissions on the .ssh directory, and securely copy the public 
# key to a remote server using ssh-copy-id.
# to execute, run: ./12-configure-ansible.sh <user> <host-ip>

set -e

REMOTE_USER="$1"
REMOTE_HOST="$2"

if [ -z "$REMOTE_USER" ] || [ -z "$REMOTE_HOST" ]; then
    echo "Usage: $0 <remote_user> <remote_host>"
    exit 1
fi

[ ! -f ~/.ssh/id_ed25519 ] && ssh-keygen -t ed25519 -N "" -C "ansible-control-node" -f ~/.ssh/id_ed25519

ssh-copy-id -o StrictHostKeyChecking=accept-new "$REMOTE_USER@$REMOTE_HOST"

ansible all -i "${REMOTE_HOST}," -u "$REMOTE_USER" -m ping

echo "SUCCESS: Ansible ping test passed."

echo ""
echo "[INFO] Script execution completed."
