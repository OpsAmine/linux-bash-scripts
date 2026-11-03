#!/bin/bash

#==============================================================================
# Script Name : docker.sh
# Description : Installs Docker Engine from Docker's official repositories,
#               automatically detecting the Linux distribution family
#               (Debian/Ubuntu or RHEL/Rocky/Fedora) and using the matching
#               package manager and repository.
#------------------------------------------------------------------------------
# What it does:
#   1. Verifies it is run as root and that /etc/os-release exists
#   2. Detects the OS from /etc/os-release (ID and ID_LIKE)
#   3. Detects an existing Docker install and asks before reinstalling
#   4. Debian family (Debian, Ubuntu and derivatives such as Mint):
#        - removes conflicting packages
#        - installs prerequisites (ca-certificates, curl)
#        - adds Docker's official GPG key and apt repository
#        - installs the Docker packages with apt
#   5. RHEL family (Rocky, AlmaLinux, RHEL, CentOS, Fedora, Oracle Linux):
#        - adds Docker's official dnf repository
#        - removes conflicting packages
#        - installs the Docker packages with dnf
#   6. Enables and starts the Docker service
#   7. Verifies the installation (docker version, compose version, service
#      status)
#
# Packages installed:
#   docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin,
#   docker-compose-plugin
#
# Supported distributions:
#   Debian, Ubuntu (and derivatives), Rocky Linux, AlmaLinux, RHEL, CentOS,
#   Fedora, Oracle Linux. Other distros are matched through ID_LIKE when
#   possible; otherwise the script exits with an error.
#
# Usage:
#   sudo ./docker.sh
#   (make it executable first with: chmod +x docker.sh)
#
# Notes:
#   - The script stops on the first error (set -euo pipefail)
#   - If Docker is already installed, you are asked whether to reinstall
#     or upgrade it
#
# Exit codes:
#   0 : Success, or the user chose not to reinstall
#   1 : Not run as root, OS detection failed, unsupported OS, or a step
#       failed
#==============================================================================

set -euo pipefail

echo "Verifying if script is run as root or sudo..."
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run script as root or using sudo." >&2
    exit 1
fi

if [ ! -f /etc/os-release ]; then
    echo "ERROR: /etc/os-release not found, cannot detect OS." >&2
    exit 1
fi

# loading operating system identification data
. /etc/os-release

OS_ID="${ID,,}"
OS_LIKE="${ID_LIKE:-}"
OS_LIKE="${OS_LIKE,,}"

if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed: $(docker --version)"
    read -r -p "Reinstall/upgrade anyway? [y/N]: " ANSWER
    [ "${ANSWER,,}" = "y" ] || exit 0
fi

echo "Detected OS: ${PRETTY_NAME:-$OS_ID}"

install_debian_family() {
    local repo_os="$OS_ID"
    local codename="${VERSION_CODENAME:-}"

    # Ubuntu derivatives as mint use the Ubuntu repo
    if [ "$OS_ID" != "ubuntu" ] && [ "$OS_ID" != "debian" ]; then
        if [ -n "${UBUNTU_CODENAME:-}" ]; then
            repo_os="ubuntu"
            codename="$UBUNTU_CODENAME"
        else
            repo_os="debian"
        fi
    fi

    echo "Step 1: Removing conflicting packages"
    apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1)

    echo "Step 2: Installing prerequisites"
    apt update -y
    apt install -y ca-certificates curl

    echo "Step 3: Adding Docker's Official GPG Key"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${repo_os}/gpg" -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo "Step 4: Adding Docker repository"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${repo_os} ${codename} stable" \
        > /etc/apt/sources.list.d/docker.sources
    apt update

    echo "Step 5: Installing Docker packages"
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_rhel_family() {
    local repo_os="rhel"
    case "$OS_ID" in
        centos) repo_os="centos" ;;
        fedora) repo_os="fedora" ;;
        *)      repo_os="rhel" ;;   # Rocky, Alma, RHEL, Oracle
    esac

    echo "Step 1: Adding Docker Repository"
    dnf config-manager --add-repo https://download.docker.com/linux/${repo_os}/docker-ce.repo

    echo "Step 1: Removing conflicting packages if exist"
    dnf remove -y docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc

    echo "step 2: Installing required packages"
    dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

case "$OS_ID" in
    ubuntu|debian)
        install_debian_family ;;
    rocky|almalinux|rhel|centos|fedora|ol)
        install_rhel_family ;;
    *)
        if [[ "$OS_LIKE" == *debian* || "$OS_LIKE" == *ubuntu* ]]; then
            install_debian_family
        elif [[ "$OS_LIKE" == *rhel* || "$OS_LIKE" == *fedora* ]]; then
            install_rhel_family
        else
            echo "ERROR: Unsupported OS: $OS_ID" >&2
            exit 1
        fi
        ;;
esac

echo "Starting and Enabling Docker"
systemctl enable --now docker

echo "Verifying installation"
docker --version
docker compose version
systemctl is-active --quiet docker && echo "Docker service is running."

echo "SUCCESS: Docker installed successfully."
