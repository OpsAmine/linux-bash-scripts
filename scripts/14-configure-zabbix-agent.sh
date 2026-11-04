#!/bin/bash

# Configure Zabbix Agent 2 by updating server addresses and hostname directives 
# in zabbix_agent2.conf, creating a timestamped backup, and restarting the service.
# Usage: sudo ./configure_zabbix_agent.sh @ZABBIX-SERVER-IP HOSTNAME
# Example: sudo ./configure_zabbix_agent.sh 192.168.1.10 web-server-01

set -euo pipefail

CONF="/etc/zabbix/zabbix_agent2.conf"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root or with sudo."
    exit 1
fi

if [ -z "${1:-}" ]; then
    echo "Usage: sudo $0 <ZABBIX_SERVER_IP> [HOSTNAME]"
    exit 1
fi

ZBX_SERVER="$1"
ZBX_HOSTNAME="${2:-$(hostname)}"

if [ ! -f "$CONF" ]; then
    echo "ERROR: $CONF not found. Is zabbix-agent2 installed?"
    exit 1
fi

BACKUP="${CONF}.bak.$(date +%F_%H%M%S)"
cp "$CONF" "$BACKUP"
echo "Backup saved to $BACKUP"

echo "Setting Server=$ZBX_SERVER, ServerActive=$ZBX_SERVER, Hostname=$ZBX_HOSTNAME"
sed -i \
    -e "s|^Server=.*|Server=${ZBX_SERVER}|" \
    -e "s|^ServerActive=.*|ServerActive=${ZBX_SERVER}|" \
    -e "s|^Hostname=.*|Hostname=${ZBX_HOSTNAME}|" \
    "$CONF"

echo "Enabling and starting zabbix-agent2..."
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

echo "Status:"
systemctl --no-pager --lines=0 status zabbix-agent2 || true

echo "[INFO] Make sure port 10050/tcp is open to the Zabbix server."

echo ""
echo "[INFO] Script execution completed."