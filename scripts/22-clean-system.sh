#!/bin/bash

# Perform routine system maintenance by clearing package manager caches 
# and removing orphaned packages (APT/DNF), vacuuming systemd journal logs 
# older than 7 days, and purging temporary files in /tmp older than 7 days, 
# featuring an optional dry-run preview mode.

# Description : Simple Linux system cleanup script
# TO USE: sudo ./run-cleanup.sh [--dry-run|-d]

set -euo pipefail

# Must be run as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root, or with sudo."
    exit 1
fi

# Handle dry-run flag
DRY_RUN=false
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-d" ]; then
    DRY_RUN=true
    echo "[DRY-RUN MODE] Simulated run, to check what changes will be made."
fi
echo ""

echo "--- Starting System Cleanup ---"

# 1. Package cache and orphaned packages
if command -v apt-get &>/dev/null; then
    echo "Cleaning APT package cache and removing orphaned packages..."
    if [ "$DRY_RUN" = false ]; then
        apt-get clean
        apt-get autoremove -y
        apt-get autoclean
    else
        echo "[DRY-RUN] Would run: apt-get clean && apt-get autoremove -y && apt-get autoclean"
    fi
elif command -v dnf &>/dev/null; then
    echo "Cleaning DNF package cache and removing orphaned packages..."
    if [ "$DRY_RUN" = false ]; then
        dnf clean all
        dnf autoremove -y
    else
        echo "[DRY-RUN] Would run: dnf clean all && dnf autoremove -y"
    fi
else
    echo "No package manager detected, skipping package cleanup."
fi

# 2. Systemd journal logs (keep last 7 days only)
if command -v journalctl &>/dev/null; then
    echo "-> Vacuuming systemd journal logs..."
    if [ "$DRY_RUN" = false ]; then
        journalctl --vacuum-time=7d
    else
        echo "[DRY-RUN] Would run: journalctl --vacuum-time=7d"
    fi
else
    echo "Journalctl not detected, skipping log vacuum."
fi

# 3. Old temporary files
echo "Removing temporary files in /tmp older than 7 days..."
if [ "$DRY_RUN" = false ]; then
    find /tmp -mindepth 1 -mtime +7 -delete 2>/dev/null || true
else
    echo "[DRY-RUN] Would delete the following files in /tmp older than 7 days:"
    find /tmp -mindepth 1 -mtime +7 2>/dev/null || true
fi

echo ""
echo "[INFO] Script execution completed."
