#!/bin/bash

#==============================================================================
# Description : Installs Chrony by automatically detecting the Linux distribution 
#               family (Debian/Ubuntu or RHEL/Rocky/Fedora) and using the matching
#               package manager and repository.
#------------------------------------------------------------------------------

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root or with sudo."
    exit 1
fi

. /etc/os-release

OS_ID="${ID,,}"

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    OS_FAMILY="debian"
    CONFIG_FILE="/etc/chrony/chrony.conf"
    SERVICE_NAME="chrony"
elif [[ "$OS_ID" == "rhel" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" || "$OS_ID" == "centos" ]]; then
    OS_FAMILY="rhel"
    CONFIG_FILE="/etc/chrony.conf"
    SERVICE_NAME="chronyd"
else
    echo "ERROR: Unsupported OS family ($OS_ID)."
    exit 1
fi

echo "Detected OS Family: $OS_FAMILY"

if ! command -v chronyd &>/dev/null; then
    echo "Installing chrony"
    if [ "$OS_FAMILY" == "debian" ]; then
        apt-get update && apt-get install -y chrony
    elif [ "$OS_FAMILY" == "rhel" ]; then
        dnf install -y chrony
    fi
else
    echo "Chrony is already installed."
fi

echo "Writing configuration to $CONFIG_FILE"

cat << EOF > "$CONFIG_FILE"
# --- UPSTREAM TIME SOURCES ---
# Use public NTP pool servers (at least 4 independent sources are recommended)
pool pool.ntp.org iburst
pool <server-name> iburst

# --- STATE & DRIFT FILES ---
# Record the rate at which the system clock gains/losses time to maintain accuracy
driftfile /var/lib/chrony/drift

# --- CLOCK TRACKING & STEPPING ---
# Step the clock instead of slewing if the offset is larger than 1 second, 
# but only during the first 3 clock updates.
makestep 1.0 3

# Update the hardware Real Time Clock (RTC) with system time
rtcsync

# If no external sources are available, look to the local clock as a fallback
# local stratum 10

# --- LOGGING ---
# Specify directory for log files and what data to log
logdir /var/log/chrony
log measurements statistics tracking
EOF

echo "Starting and Enabling $SERVICE_NAME"
systemctl enable --now "$SERVICE_NAME"

if ! systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1; then
    echo "ERROR: $SERVICE_NAME cannot be started, check journald."
    exit 1
else 
    sleep 2
    chronyc activity
    chronyc sources -v

    echo "DONE: Chrony installation and configuration completed."
fi

echo "[ INFO ] Script have finished executing. Bye !"
