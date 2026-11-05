#!/bin/bash

# Extract a compressed archive (tar.gz, tgz, tar.bz2, tar.xz, tar, zip, gz,
# bz2, xz) into a target destination directory, verifying the archive
# exists and detecting the format from its file extension.
# TO USE : 1. Archive:  ./21-extract-file.sh /data/backups/docker-2026-11-05.tar.gz /tmp/restore

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <archive_file> <destination_directory>"
    exit 1
fi

ARCHIVE="$1"
DEST_DIR="$2"

if [ ! -f "$ARCHIVE" ]; then
    echo "ERROR: Archive does not exist: $ARCHIVE"
    exit 1
fi

mkdir -p "$DEST_DIR"

echo "Extracting $ARCHIVE to $DEST_DIR..."

case "$ARCHIVE" in
    *.tar.gz|*.tgz)
        tar -xzf "$ARCHIVE" -C "$DEST_DIR"
        ;;
    *.tar.bz2|*.tbz2)
        tar -xjf "$ARCHIVE" -C "$DEST_DIR"
        ;;
    *.tar.xz|*.txz)
        tar -xJf "$ARCHIVE" -C "$DEST_DIR"
        ;;
    *.tar)
        tar -xf "$ARCHIVE" -C "$DEST_DIR"
        ;;
    *.zip)
        if ! command -v unzip >/dev/null 2>&1; then
            echo "ERROR: unzip is not installed."
            exit 1
        fi
        unzip -q "$ARCHIVE" -d "$DEST_DIR"
        ;;
    *.gz)
        gunzip -c "$ARCHIVE" > "$DEST_DIR/$(basename "${ARCHIVE%.gz}")"
        ;;
    *.bz2)
        bunzip2 -c "$ARCHIVE" > "$DEST_DIR/$(basename "${ARCHIVE%.bz2}")"
        ;;
    *.xz)
        unxz -c "$ARCHIVE" > "$DEST_DIR/$(basename "${ARCHIVE%.xz}")"
        ;;
    *)
        echo "ERROR: Unsupported archive format: $ARCHIVE"
        exit 1
        ;;
esac

echo "Extracted to: $DEST_DIR"

echo ""
echo "[INFO] Script execution completed."
