#!/bin/bash
set -euo pipefail

NFS_SERVER="10.42.0.1"
NFS_EXPORT="${NFS_SERVER}:/shared"
MOUNT_POINT="/shared"
FSTAB_FILE="/etc/fstab"
FSTAB_ENTRY="${NFS_EXPORT} ${MOUNT_POINT} nfs defaults,_netdev,nofail,x-systemd.automount 0 0"

echo "Configuring NFS client..."

# Ensure the script is running as root
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run this script as root (using sudo)."
    exit 1
fi

# Install NFS client package
apt-get update
apt-get install -y nfs-common

# Create the mount point
install -d -m 0755 "$MOUNT_POINT"

# Add the NFS mount to /etc/fstab if it does not already exist
if ! grep -qE '^[[:space:]]*10\.42\.0\.1:/shared[[:space:]]+/shared[[:space:]]' "$FSTAB_FILE"; then
    echo "$FSTAB_ENTRY" >> "$FSTAB_FILE"
    echo "Added NFS mount to /etc/fstab."
else
    echo "NFS mount already exists in /etc/fstab."
fi

# Reload systemd configuration
systemctl daemon-reload

# Mount the shared filesystem
mount "$MOUNT_POINT"

# Verify the mount
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "ERROR: NFS share was not mounted successfully."
    exit 1
fi

echo
echo "NFS client configured successfully."
echo "NFS server: $NFS_SERVER"
echo "Remote directory: $NFS_EXPORT"
echo "Local mount point: $MOUNT_POINT"
echo

df -h "$MOUNT_POINT"
