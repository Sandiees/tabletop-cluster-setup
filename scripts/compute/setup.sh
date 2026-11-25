#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script with sudo."
    exit 1
fi

echo "======================================"
echo " Configuring compute node: $(hostname)"
echo "======================================"

# Install common software
bash "$REPO_DIR/scripts/common/install_packages.sh"

bash "$REPO_DIR/scripts/common/configure_hosts.sh"

bash "$SCRIPT_DIR/configure_network.sh"

# Mount the shared filesystem
bash "$SCRIPT_DIR/configure_shared_storage.sh"

# Configure Munge authentication
bash "$SCRIPT_DIR/configure_munge.sh"

# Install the shared Slurm configuration
bash "$SCRIPT_DIR/configure_slurm.sh"

# Configure Lmod and the shared module path
bash "$SCRIPT_DIR/configure_lmod.sh"

# Install and configure Node Exporter
bash "$SCRIPT_DIR/install_node_exporter.sh"

echo
echo "Compute-node setup completed."
echo "A reboot may be required before all services are fully operational."