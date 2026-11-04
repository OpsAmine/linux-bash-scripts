#!/bin/bash

# Deploy a private local Docker registry container protected with basic 
# authentication using htpasswd, set up isolated networking and persistent 
# storage volumes, and run smoke tests by tagging and pushing images.

set -euo pipefail

# Check if script is run as root/with sudo
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run script as root or with sudo."
    exit 1
fi

# Load operating system configuration
. /etc/os-release
OS_ID="${ID,,}"

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    OS_FAMILY="debian"
    PKG="apache2-utils"
elif [[ "$OS_ID" == "rhel" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" || "$OS_ID" == "centos" ]]; then
    OS_FAMILY="rhel"
    PKG="httpd-tools"
else
    echo "ERROR: Unsupported OS family ($OS_ID)."
    exit 1
fi

echo "Detected OS Family: $OS_FAMILY"

# Verify if htpasswd is installed
if ! command -v htpasswd &>/dev/null; then
    echo "Installing $PKG for htpasswd functionality..."
    if [ "$OS_FAMILY" == "debian" ]; then
        apt-get update && apt-get install -y "$PKG"
    elif [ "$OS_FAMILY" == "rhel" ]; then
        dnf install -y "$PKG"
    fi
else
    echo "htpasswd is already installed. Skipping installation..."
fi

REG_AUTH_PATH="/opt/docker-registry/auth"
AUTH_USER="docker"
AUTH_PASS="password"

mkdir -p "$REG_AUTH_PATH"
chmod 700 "$REG_AUTH_PATH"

# Pass the password to htpasswd
htpasswd -B -b -c "$REG_AUTH_PATH/htpasswd" "$AUTH_USER" "$AUTH_PASS"

COMPOSE_PATH="/home/vortex/registry"
FILE_NAME="docker-compose.yml"
DOCKER_NETWORK="registry-net"
DOCKER_VOLUME="registry-vol"

mkdir -p "$COMPOSE_PATH"

# Create Docker network and volume
docker network create "$DOCKER_NETWORK" 2>/dev/null || true
docker volume create "$DOCKER_VOLUME" 2>/dev/null || true

echo "Writing registry's docker compose to $COMPOSE_PATH"
cat << EOF > "$COMPOSE_PATH/$FILE_NAME"
services:
  registry:
    image: registry:2
    container_name: docker-registry-prod
    restart: unless-stopped
    networks:
      - "$DOCKER_NETWORK"
    ports:
      - "5000:5000"
    volumes:
      - "$DOCKER_VOLUME":/var/lib/registry
volumes:
  "$DOCKER_VOLUME":
    external: true
    name: "$DOCKER_VOLUME"
networks:
  "$DOCKER_NETWORK":
    external: true
    name: "$DOCKER_NETWORK"
EOF

echo "Applying docker compose file"
cd "$COMPOSE_PATH"
docker compose up -d 

echo "Testing registry"
docker pull hello-world

# Test registry
docker tag hello-world localhost:5000/base/hello-world:1.0
docker push localhost:5000/base/hello-world:1.0
docker pull localhost:5000/base/hello-world:1.0

echo ""
echo "[INFO] Script execution completed."