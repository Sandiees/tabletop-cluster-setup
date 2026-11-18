#!/bin/bash
set -euo pipefail

SHARED_DIR="/shared"
NFS_EXPORT="master:/shared"
FSTAB_ENTRY="$NFS_EXPORT $SHARED_DIR nfs defaults,_netdev,x-systemd.automount 0 0"

apt-get install -y nfs-common

install -d -m 0755 "$SHARED_DIR"

if ! grep -qF "$NFS_EXPORT $SHARED_DIR " /etc/fstab; then
    echo "$FSTAB_ENTRY" >> /etc/fstab
fi

systemctl daemon-reload

echo "Shared storage mount configured."
echo "It will be mounted automatically when /shared is accessed."