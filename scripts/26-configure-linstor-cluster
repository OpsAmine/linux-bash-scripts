#!/bin/bash

# Description: Deploy a LINSTOR cluster. 
# Requirements: Run as root on the controller host.

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root, or with sudo." >&2
    exit 1
fi

CONTROLLER="TST-SRV-001"
STORAGE_POOL="drbdpool"
VG_NAME="linstor_vg"

declare -A NODE_IP=(
    ["TST-SRV-001"]="X.X.X.X"
    ["TST-SRV-002"]="X.X.X.X"
    ["TST-SRV-003"]="X.X.X.X"
)
NODE_LIST=("TST-SRV-001" "TST-SRV-002" "TST-SRV-003")

echo "Testing Connectivity from $CONTROLLER to Satellites"
for node in "${NODE_LIST[@]}"; do
    if ! ping -c 2 -W 2 "${NODE_IP[$node]}" >/dev/null; then
        echo "ERROR: $node (${NODE_IP[$node]}) unreachable." >&2
        exit 1
    fi
done

echo "Creating Cluster Nodes"
existing_nodes=$(linstor --no-color node list 2>/dev/null || true)
for node in "${NODE_LIST[@]}"; do
    if grep -qw "$node" <<<"$existing_nodes"; then
        echo "Node $node already exists, skipping."
        continue
    fi

    if [ "$node" = "$CONTROLLER" ]; then
        linstor node create "$node" "${NODE_IP[$node]}" --node-type combined
    else
        linstor node create "$node" "${NODE_IP[$node]}" --node-type satellite
    fi
done

echo "Creating storage pools"
for node in "${NODE_LIST[@]}"; do
    if linstor --no-color storage-pool list -n "$node" 2>/dev/null | grep -qw "$STORAGE_POOL"; then
        echo "Pool $STORAGE_POOL already exists on $node, skipping."
    else
        linstor storage-pool create lvm "$node" "$STORAGE_POOL" "$VG_NAME"
    fi
done

echo "Cluster state:"
linstor node list
linstor storage-pool list

echo ""
echo "[INFO] Script execution completed."
