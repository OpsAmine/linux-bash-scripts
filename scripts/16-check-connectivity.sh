#!/bin/bash

# Prompt for a target URL or IP address, normalize the protocol prefix, 
# and execute an insecure HTTP HEAD request via curl with a timeout limit 
# to verify network connectivity and response headers.

set -euo pipefail

read -p "Enter the URL or IP to test (e.g. google.com): " USER_INPUT

if [[ ! $USER_INPUT =~ ^https?:// ]]; then
    echo "No http/https included, default to https://"
    URL="https://$USER_INPUT"
else
    URL="$USER_INPUT"
fi

echo ""

echo " --- CONNECTIVITY CHECK --- "
echo "Target: $URL"
echo "Timestamp: $(date)"
echo " -------------------------- "
curl -k -I --max-time 10 "$URL"

echo ""
echo "[INFO] Script execution completed."
