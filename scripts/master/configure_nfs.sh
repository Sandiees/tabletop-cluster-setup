#!/bin/bash
set -euo pipefail

SHARED_DIR="/shared"
HOME_DIR="/home"
EXPORT_DIR="/etc/exports.d"
EXPORT_FILE="$EXPORT_DIR/cluster.exports"
CLUSTER_NETWORK="10.42.0.0/24"

echo "Configuring NFS server..."

# Ensure the script is running as root
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run this script as root (using sudo)."
    exit 1
fi

# Check that the private cluster interface is configured
if ! ip -4 addr show dev eth0 | grep -q "10.42.0.1/24"; then
    echo "ERROR: eth0 does not have address 10.42.0.1/24."
    echo "Configure the cluster LAN before setting up NFS."
    exit 1
fi

# Install NFS server package
apt-get update
apt-get install -y nfs-kernel-server

# Create the shared directory and standard subdirectories
install -d -m 0755 "$SHARED_DIR"
install -d -m 0755 "$SHARED_DIR/modulefiles"
install -d -m 0755 "$SHARED_DIR/examples"

# Ensure the master home directory exists
install -d -m 0755 "$HOME_DIR"

# Create the NFS exports directory
mkdir -p "$EXPORT_DIR"

# Configure both exports
cat > "$EXPORT_FILE" <<EOF
# Raspberry Pi cluster shared directory
$SHARED_DIR $CLUSTER_NETWORK(rw,sync,root_squash,no_subtree_check)

# User home directories shared with compute nodes
$HOME_DIR $CLUSTER_NETWORK(rw,sync,root_squash,no_subtree_check)
EOF

chmod 0644 "$EXPORT_FILE"

# Apply export configuration
exportfs -rav

# Enable and start NFS server
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server

# Verify both exports
if ! exportfs -s | grep -q "$SHARED_DIR"; then
    echo "ERROR: $SHARED_DIR was not exported successfully."
    exit 1
fi

if ! exportfs -s | grep -q "$HOME_DIR"; then
    echo "ERROR: $HOME_DIR was not exported successfully."
    exit 1
fi

echo
echo "NFS server configured successfully."
echo "Exported directories:"
echo "  $SHARED_DIR"
echo "  $HOME_DIR"
echo "Allowed network: $CLUSTER_NETWORK"
echo
exportfs -v
