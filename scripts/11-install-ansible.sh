#!/bin/bash

# Automatically detect the Linux distribution, configure necessary repositories 
# (such as EPEL for RHEL-based systems or the official PPA for Ubuntu), 
# and install Ansible.

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root or with sudo."
    exit 1
fi

if [ ! -f /etc/os-release ]; then
    echo "ERROR: Cannot detect OS (/etc/os-release not found)."
    exit 1
fi

. /etc/os-release
OS_ID="${ID,,}"

case "$OS_ID" in
    ubuntu)
        apt-get update
        apt-get install -y software-properties-common
        add-apt-repository --yes --update ppa:ansible/ansible
        apt-get install -y ansible
        ;;
    debian)
        apt-get update
        apt-get install -y ansible
        ;;
    rhel|rocky|almalinux|centos)
        dnf install -y epel-release
        dnf install -y ansible-core
        ;;
    *)
        echo "ERROR: Unsupported OS ($OS_ID)."
        exit 1
        ;;
esac

if ! ansible --version >/dev/null 2>&1; then
    echo "ERROR: Ansible is not installed."
    exit 1
fi

ansible --version

echo ""
echo "[INFO] Script execution completed."
