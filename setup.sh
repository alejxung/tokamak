#!/bin/bash

# Configuration
ALPINE_VERSION="3.20.0"
ARCH="x86_64"
ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"
VACUUM_DIR="./vacuum_root"

# Function to check for a command
check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo "[Error] '$1' is not installed. Please install it."
        exit 1
    fi
}

echo "=== Tokamak Initialization Sequence ==="

# Host Check
echo "[Init] Checking Host System..."
check_cmd g++
check_cmd wget
check_cmd tar

# Check for libseccomp (Debian/Ubuntu/OrbStack specific)
if ! ldconfig -p | grep -q libseccomp; then
    echo "    [Warning] libseccomp not found. Attempting to install..."
    # This might ask for sudo password
    sudo apt update && sudo apt install -y libseccomp-dev
fi

# Vacuum Setup
if [ -d "$VACUUM_DIR" ]; then
    echo "[Init] Vacuum directory exists. Skipping download."
else
    echo "[Init] Creating Vacuum Chamber..."
    mkdir -p "$VACUUM_DIR"
    echo "    -> Downloading Alpine Linux v${ALPINE_VERSION}..."
    wget -q -O alpine_rootfs.tar.gz "$ROOTFS_URL"
    
    if [ $? -ne 0 ]; then
        echo "[Error] Failed to download Alpine Linux."
        exit 1
    fi

    echo "    -> Extracting filesystem..."
    tar -xzf alpine_rootfs.tar.gz -C "$VACUUM_DIR"
    rm alpine_rootfs.tar.gz
fi

# Hardening
echo "[Init] Hardening Filesystem..."
rm -f "$VACUUM_DIR/etc/hostname"
rm -f "$VACUUM_DIR/etc/passwd"
rm -f "$VACUUM_DIR/etc/shadow"

# Build Reactor
echo "[Build] Compiling Reactor Core..."
if [ -f "reactor.cpp" ]; then
    g++ -o reactor reactor.cpp -lseccomp
    if [ $? -eq 0 ]; then
        echo "    -> Success: './reactor' binary created."
    else
        echo "    [Error] Compilation failed."
        exit 1
    fi
else
    echo "    [Error] reactor.cpp not found!"
    exit 1
fi

# Build Tests (Malware)
echo "[Build] Compiling Test Payloads..."
if [ -f "malware.cpp" ]; then
    g++ -static -o malware malware.cpp
    cp malware "$VACUUM_DIR/bin/malware"
    echo "    -> Malware installed to Vacuum /bin/malware."
fi

echo "======================================="
echo "   SYSTEM READY."
echo "   Test Command: sudo ./reactor /bin/malware"
echo "======================================="