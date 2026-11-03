#!/bin/bash

#==============================================================================
# Description : Moves Docker's data directory from /var/lib/docker to a new
#               directory (default /data/docker) and configures the Docker
#               daemon to use it, with a hardened set of daemon options.
#------------------------------------------------------------------------------

set -euo pipefail

SOURCE_DIR="/var/lib/docker"
TARGET_DIR="/data/docker"
DAEMON_JSON="/etc/docker/daemon.json"
 
echo "Verifying if script is run as root or sudo..."
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run script as root or using sudo." >&2
    exit 1
fi
 
echo "Verifying existence of necessary packages..."
for cmd in docker rsync; do
    if ! command -v "$cmd">/dev/null 2>&1; then
        echo "ERROR: Required command '$cmd' not found." >&2
        if [ "$cmd" = "rsync" ]; then
            echo "Installing missing $cmd package"
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y rsync
            elif command -v apt-get >/dev/null 2>&1; then
                apt-get update -y
                apt-get install -y rsync
            else
                echo "ERROR: No supported package manager found to install rsync." >&2
                exit 1
            fi
        else
            echo "Install '$cmd' first (see getdocker.sh for Docker)." >&2
            exit 1
        fi
    fi
done
 
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory $SOURCE_DIR does not exist." >&2
    exit 1
fi
 
echo "Stopping running containers..."

RUNNING="$(docker ps -q 2>/dev/null || true)"
if [ -n "$RUNNING" ]; then
    docker stop $RUNNING
fi
 
echo "Stopping docker service..."

systemctl stop docker.socket 2>/dev/null || true
systemctl stop docker
 
echo "Creating directory $TARGET_DIR"

mkdir -p "$TARGET_DIR"
chmod 710 "$TARGET_DIR"
 
echo "Configuring $DAEMON_JSON"

mkdir -p "$(dirname "$DAEMON_JSON")"
if [ -f "$DAEMON_JSON" ]; then 
    cp "$DAEMON_JSON" "${DAEMON_JSON}.bak-$(date +%F-%H%M%S)"
fi
cat > "$DAEMON_JSON" << EOF
{
  "storage-driver": "overlay2",
  "data-root": "/data/docker",
  "log-driver": "journald",
  "live-restore": true,
  "no-new-privileges": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65535,
      "Soft": 65535
    }
  },
  "init": true
}
EOF
 
echo "Syncing $SOURCE_DIR to $TARGET_DIR"

rsync -aHAXS --numeric-ids --partial --info=progress2 "$SOURCE_DIR"/ "$TARGET_DIR"/
 
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" = "Enforcing" ]; then
    echo "Applying SELinux contexts to $TARGET_DIR"
    if command -v semanage >/dev/null 2>&1; then
        semanage fcontext -a -e "$SOURCE_DIR" "$TARGET_DIR" 2>/dev/null || true
    fi
    restorecon -R "$TARGET_DIR"
fi
 
echo "Starting Docker service"

systemctl daemon-reload
systemctl start docker
 
echo "Verifying Docker data-root..."

ROOT_DIR="$(docker info -f '{{.DockerRootDir}}')"

if [ "$ROOT_DIR" != "$TARGET_DIR" ]; then
    echo "ERROR: Docker is using $ROOT_DIR instead of $TARGET_DIR." >&2
    exit 1
fi
 
echo "SUCCESS: Docker data moved from $SOURCE_DIR to $TARGET_DIR."

echo "[ NOTE ] You can remove old directory using : sudo rm -rf $SOURCE_DIR"
