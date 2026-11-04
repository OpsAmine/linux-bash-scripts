#!/bin/bash

# Apply production kernel tuning parameters for network security hardening 
# (SYN cookies, reverse path filtering, redirect blocking) and resource scaling 
# (file descriptors, memory maps, swappiness, backlog limits) via sysctl.

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run script as root, or with sudo."
    exit 1
fi

SYSCTL_CONF="/etc/sysctl.d/99-server-optimization.conf"

cat << 'EOF' > "$SYSCTL_CONF"
# Enable SYN cookie protection against SYN flood denial of service
net.ipv4.tcp_syncookies = 1

# Protect against IP Spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Refuse ICMP redirects to prevent MITM route alteration
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# Deny sending ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Ignore fake or broadcast ICMP echo requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Max physical file descriptors/handles system can allocate globally
fs.file-max = 2097152

# Max memory map allocations
vm.max_map_count = 262144

# Keep system responsive by preventing early swapping onto slow disk blocks
vm.swappiness = 10

# Max network connection backlog pipeline queue depth
net.core.somaxconn = 4096
EOF

echo "Applying runtime configurations..."

# Re-load sysctl settings 
sysctl --system

echo "[SUCCESS] Sysctl parameters loaded and enforced successfully."

echo ""
echo "[INFO] Script execution completed."