#!/bin/bash
set -euo pipefail

NFS_SERVER="10.42.0.1"
NFS_EXPORT="${NFS_SERVER}:/home"
MOUNT_POINT="/home"
FSTAB_FILE="/etc/fstab"
FSTAB_ENTRY="${NFS_EXPORT} ${MOUNT_POINT} nfs4 rw,hard,_netdev 0 0"

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run this script as root (using sudo)."
    exit 1
fi

echo "Configuring shared home directories..."

apt-get update
apt-get install -y nfs-common

install -d -m 0755 "$MOUNT_POINT"

# Remove any existing local home directories on the compute node.
# Do not delete anything if /home is already mounted.
if mountpoint -q "$MOUNT_POINT"; then
    echo "/home is already mounted. Keeping the existing mount."
else
    echo "Removing existing local contents of /home..."
    find "$MOUNT_POINT" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
fi

# Avoid accidentally creating duplicate or conflicting /home entries.
if grep -qE '^[^#].*[[:space:]]/home[[:space:]]' "$FSTAB_FILE"; then
    if ! grep -qF "$FSTAB_ENTRY" "$FSTAB_FILE"; then
        echo "ERROR: /etc/fstab already contains a conflicting /home mount entry."
        echo "Please check it and replace it with:"
        echo "$FSTAB_ENTRY"
        exit 1
    fi
else
    echo "$FSTAB_ENTRY" >> "$FSTAB_FILE"
    echo "Added /home NFS mount to /etc/fstab."
fi

# Ensure slurmd cannot start before the shared home filesystem is available.
SLURMD_DROPIN="/etc/systemd/system/slurmd.service.d/home.conf"
install -d -m 0755 "$(dirname "$SLURMD_DROPIN")"

cat > "$SLURMD_DROPIN" <<'EOF'
[Unit]
RequiresMountsFor=/home
EOF

systemctl daemon-reload

# Mount /home now, rather than waiting for the first access.
if ! mountpoint -q "$MOUNT_POINT"; then
    mount "$MOUNT_POINT"
fi

# Verify that /home is actually backed by an NFS filesystem.
FSTYPE="$(findmnt -n -o FSTYPE --target "$MOUNT_POINT")"
if [[ "$FSTYPE" != "nfs" && "$FSTYPE" != "nfs4" ]]; then
    echo "ERROR: /home is not mounted using NFS (detected: $FSTYPE)."
    exit 1
fi

echo
echo "Shared home directory configured successfully."
findmnt "$MOUNT_POINT"
