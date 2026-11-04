#!/bin/bash

# Initialize a base nftables packet filtering framework, ensure the service 
# is active, and provide modular rule templates for managing port access 
# and IP subnet restrictions.

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root or with sudo."
    exit 1
fi

SERVICE="nftables"
PORT="22"
PROTOCOL="tcp"
IP_RANGE="192.168.0.1/24"

# FIXED: Standardized service activation check and string output
if ! systemctl is-active "$SERVICE" >/dev/null 2>&1 ; then
    echo "Service $SERVICE is inactive, activating (enable and start)..."
    systemctl enable --now "$SERVICE"
fi

echo "--- Initializing base structure ---"
echo "--- Create the table framework ---"
nft add table inet filter

echo "--- Creating the missing 'input' chain with hooks ---"
nft add chain inet filter input { type filter hook input priority 0 \; policy accept \; }

# FIREWALL RULES: Un-comment ONLY what to use

# --- DROP (Silent Block) ---
# nft add rule inet filter input "$PROTOCOL" dport "$PORT" drop

# --- REJECT (Active Block / Deny) ---
# nft add rule inet filter input "$PROTOCOL" dport "$PORT" reject

# --- ACCEPT (Allow) ---
# nft add rule inet filter input "$PROTOCOL" dport "$PORT" accept

# --- IP-SPECIFIC RULES ---
# nft add rule inet filter input ip saddr "$IP_RANGE" "$PROTOCOL" dport "$PORT" accept

# Block/Deny traffic on a specific port from an untrusted subnet range
# nft add rule inet filter input ip saddr "$IP_RANGE" "$PROTOCOL" dport "$PORT" drop

# --- Show current running configuration ---
echo "--- Current Running nftables Configuration ---"
nft list table inet filter

echo ""
echo "[INFO] Script execution completed."
