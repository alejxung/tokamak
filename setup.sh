#!/bin/bash

# Configuration
ALPINE_VERSION="3.20.0"
ARCH="x86_64"
ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"
VACUUM_DIR="./vacuum_root"

# Check if Vacuum already exists
if [ -d "$VACUUM_DIR" ]; then
    echo "[Setup] Vacuum chamber ($VACUUM_DIR) already exists. Skipping."
    exit 0
fi

echo "[Setup] Initializing Vacuum Chamber..."

# Create Directory
mkdir -p "$VACUUM_DIR"

# Download Alpine Linux RootFS
echo "[Setup] Downloading Alpine Linux v${ALPINE_VERSION}..."
wget -q -O alpine_rootfs.tar.gz "$ROOTFS_URL"

if [ $? -ne 0 ]; then
    echo "[Error] Failed to download Alpine Linux."
    rm alpine_rootfs.tar.gz
    rmdir "$VACUUM_DIR"
    exit 1
fi

# Extract (Install the walls of the chamber)
echo "[Setup] Extracting filesystem..."
tar -xzf alpine_rootfs.tar.gz -C "$VACUUM_DIR"

# Cleanup
rm alpine_rootfs.tar.gz

echo "[Setup] Vacuum Chamber ready."
echo "        To test: sudo ./reactor /bin/ls -la /"