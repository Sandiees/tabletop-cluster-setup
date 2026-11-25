#!/bin/bash
set -euo pipefail

SHARED_DIR="/shared"
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

# Create the NFS exports directory
mkdir -p "$EXPORT_DIR"

# Configure the export
cat > "$EXPORT_FILE" <<EOF
# Raspberry Pi cluster shared directory
$SHARED_DIR $CLUSTER_NETWORK(rw,sync,root_squash,no_subtree_check)
EOF

chmod 0644 "$EXPORT_FILE"

# Apply export configuration
exportfs -rav

# Enable and start NFS server
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server

# Verify the export
if ! exportfs -s | grep -q "$SHARED_DIR"; then
    echo "ERROR: /shared was not exported successfully."
    exit 1
fi

echo
echo "NFS server configured successfully."
echo "Exported directory: $SHARED_DIR"
echo "Allowed network: $CLUSTER_NETWORK"
echo
exportfs -v