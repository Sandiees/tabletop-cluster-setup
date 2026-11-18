#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG_SOURCE="$REPO_DIR/config/common/slurm.conf"
CONFIG_DIR="/etc/slurm"
SPOOL_DIR="/var/lib/slurm/slurmd"

if [[ ! -f "$CONFIG_SOURCE" ]]; then
    echo "ERROR: Slurm configuration not found: $CONFIG_SOURCE"
    exit 1
fi

# Install the cluster-wide configuration
install -d -m 0755 "$CONFIG_DIR"
install -o root -g root -m 0644 \
    "$CONFIG_SOURCE" "$CONFIG_DIR/slurm.conf"

# Create the local Slurm spool directory
install -d -o slurm -g slurm -m 0755 "$SPOOL_DIR"

# Ensure the compute daemon starts at boot
systemctl enable slurmd

echo "Slurm configured for $(hostname)."