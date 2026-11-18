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

# 1. Install common software
bash "$REPO_DIR/scripts/common/install_packages.sh"

# 2. Configure Munge authentication
bash "$SCRIPT_DIR/configure_munge.sh"

# 3. Install the shared Slurm configuration
bash "$SCRIPT_DIR/configure_slurm.sh"

# 4. Configure Lmod and the shared module path
bash "$SCRIPT_DIR/configure_lmod.sh"

# 5. Mount the shared filesystem
bash "$SCRIPT_DIR/configure_shared_storage.sh"

# 6. Install and configure Node Exporter
bash "$SCRIPT_DIR/install_node_exporter.sh"

echo
echo "Compute-node setup completed."
echo "A reboot may be required before all services are fully operational."