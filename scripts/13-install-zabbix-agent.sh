#!/bin/bash

# Automatically detect the Linux distribution, configure the official Zabbix 
# repository (handling EPEL exclusions on RHEL-based systems), and install 
# Zabbix Agent 2 using the appropriate package manager.

set -euo pipefail

ZABBIX_VERSION="7.0"


if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root or with sudo."
    exit 1
fi

. /etc/os-release
OS_ID="${ID,,}"
OS_MAJOR="${VERSION_ID%%.*}"

case "$OS_ID" in
    ubuntu|debian)
        DEB_FILE="zabbix-release_latest_${ZABBIX_VERSION}+${OS_ID}${VERSION_ID}_all.deb"
        DEB_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/${OS_ID}/pool/main/z/zabbix-release/${DEB_FILE}"

        echo "Downloading Zabbix repo package: $DEB_URL"
        wget -q -O "/tmp/${DEB_FILE}" "$DEB_URL"

        echo "Installing Zabbix repo package..."
        dpkg -i "/tmp/${DEB_FILE}"
        rm -f "/tmp/${DEB_FILE}"

        apt-get update
        apt-get install -y zabbix-agent2
        ;;

    rhel|rocky|centos|almalinux|alma)
        EPEL_REPO="/etc/yum.repos.d/epel.repo"
        if [ -f "$EPEL_REPO" ] && ! grep -q "^excludepkgs=zabbix" "$EPEL_REPO"; then
            echo "-> Excluding zabbix* packages from EPEL..."
            sed -i '/^\[epel\]$/a excludepkgs=zabbix*' "$EPEL_REPO"
        fi

        RPM_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/rhel/${OS_MAJOR}/x86_64/zabbix-release-latest-${ZABBIX_VERSION}.el${OS_MAJOR}.noarch.rpm"

        echo "-> Installing Zabbix repo package: $RPM_URL"
        rpm -Uvh "$RPM_URL"

        dnf clean all
        dnf install -y zabbix-agent2
        ;;

    *)
        echo "ERROR: $OS_ID is not supported."
        exit 1
        ;;
esac

echo ""
echo "[INFO] Script execution completed."