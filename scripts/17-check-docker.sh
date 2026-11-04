#!/bin/bash

# Collect and report essential Docker diagnostics: installation binaries, 
# daemon systemd runtime status, active storage directories, disk utilization, 
# container counts, and daemon configuration parameters.
set -euo pipefail

# FIXED: Added missing space before the closing bracket
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root or with sudo."
    exit 1
fi

echo "--- Verifying Installation & Version Used --- "
if command -v docker &>/dev/null; then
    echo "Docker Binary:   INSTALLED ($(which docker)) "
    # FIXED: Re-structured the subshell syntax, format quotes, and fallback nesting cleanly
    echo "Docker Engine:   $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "Unknown (Daemon unreachable)")"
    echo "Docker Compose:  $(docker compose version 2>/dev/null || echo "Not installed")"
else
    echo "ERROR: Docker have not been found (MISSING/NOT INSTALLED) "
    exit 1 # FIXED: Halt script execution if core dependency is absent
fi
echo ""

echo "--- Verifying Daemon Systemd Runtime Status --- "
SERVICE="docker"

if systemctl list-unit-files --type=service | grep -qw "${SERVICE}.service"; then
    LOAD_STATUS=$(systemctl is-enabled "$SERVICE" 2>/dev/null || echo "unknown")
    ACTIVE_STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "inactive")

    echo "Systemd Service:     ${SERVICE}.service "
    echo "Startup Behavior:    $LOAD_STATUS "
    echo "Running State:       $ACTIVE_STATUS "

    # FIXED: Corrected case-sensitivity error ($ACTIVe_STATUS -> $ACTIVE_STATUS)
    if [ "$ACTIVE_STATUS" != "active" ]; then
        echo " [WARNING] Daemon is dead. Pulling latest systemd errors "
        journalctl -u docker -n 5 --no-pager | sed 's/^/    /'
    fi
else
    echo " [FAILED] Systemd target 'docker.service' could not be found "
fi
echo ""

echo "--- Extracting Storage Path Information --- "
if systemctl is-active "$SERVICE" >/dev/null 2>&1; then
    DOCKER_ROOT=$(docker info --format '{{.DockerRootDir}}')
    STORAGE_DRIVER=$(docker info --format '{{.Driver}}')
    C_RUNNING=$(docker info --format '{{.ContainersRunning}}')
    C_STOPPED=$(docker info --format '{{.ContainersStopped}}')

    echo "Docker Root Path:    $DOCKER_ROOT "
    # FIXED: Corrected target variable reference ($DOCKER_DRIVER -> $STORAGE_DRIVER)
    echo "Storage Driver:      $STORAGE_DRIVER "
    echo "Active Containers:   $C_RUNNING running / $C_STOPPED stopped"

    echo ""
    echo "Disk Usage Profile for Root Path ($DOCKER_ROOT):"
    df -h "$DOCKER_ROOT" | awk 'NR==1 || NR==2' | sed 's/^/ /'
else
    echo "Cannot extract runtime storage topology because daemon is off "
fi
echo ""

echo "--- Verifying Daemon Runtime Configuration --- "
CONFIG_FILE="/etc/docker/daemon.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "Configuration file found: $CONFIG_FILE "
    echo "File Contents:"
    cat "$CONFIG_FILE" | sed 's/^/  /'
else
    echo "Configuration File: Clear (Using default) "
fi

# echo "List Dangling Volumes"
# docker volume ls --filter dangling=true

# echo "List Dangling Images"
# docker image ls --filter dangling=true

echo ""
echo "[INFO] Script execution completed."

