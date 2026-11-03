#!/bin/bash

#==============================================================================
# Description : Installs Docker Engine from Docker's official repositories,
#               automatically detecting the Linux distribution family
#               (Debian/Ubuntu or RHEL/Rocky/Fedora) and using the matching
#               package manager and repository.
#------------------------------------------------------------------------------

set -euo pipefail

# Verify if script is run as root or sudo
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run script as root or using sudo." >&2
    exit 1
fi

# Loading operating system identification data
. /etc/os-release

OS_ID="${ID,,}"
OS_LIKE="${ID_LIKE:-}"
OS_LIKE="${OS_LIKE,,}"

# Check if Docker is Installed
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

    echo "Step 2: Removing conflicting packages if exist"
    dnf remove -y docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc

    echo "step 3: Installing required packages"
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
echo "[NOTE] To test on a simple container, run the following command : docker run --rm hello-world"
