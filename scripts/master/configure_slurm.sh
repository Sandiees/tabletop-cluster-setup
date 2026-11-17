#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG_SOURCE="$REPO_DIR/config/common/slurm.conf"
CONFIG_DEST="/etc/slurm/slurm.conf"

echo "Configuring Slurm..."

if [[ "$(hostname -s)" != "master-node" ]]; then
    echo "ERROR: This machine's hostname is not 'master-node'."
    echo "Set it with: sudo hostnamectl set-hostname master-node"
    exit 1
fi

if ! id slurm >/dev/null 2>&1; then
    echo "ERROR: Slurm user does not exist."
    exit 1
fi

if [[ ! -f "$CONFIG_SOURCE" ]]; then
    echo "ERROR: Could not find $CONFIG_SOURCE"
    exit 1
fi

mkdir -p /etc/slurm
install -o root -g root -m 0644 "$CONFIG_SOURCE" "$CONFIG_DEST"

mkdir -p /var/lib/slurm/slurmctld
mkdir -p /var/lib/slurm/slurmd
mkdir -p /var/log/slurm

chown -R slurm:slurm /var/lib/slurm
chown -R slurm:slurm /var/log/slurm

echo "Enabling Slurm controller..."
systemctl enable slurmctld

systemctl restart slurmctld

echo "Slurm controller configuration complete."