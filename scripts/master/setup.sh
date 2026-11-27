#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo " Starting master-node configuration"
echo "======================================"

echo "Installing common packages..."
bash "$SCRIPT_DIR/../common/install_packages.sh"

echo "Configuring hostnames..."
bash "$SCRIPT_DIR/../common/configure_hosts.sh"

echo "======================================"
echo "Configuring network sharing..."
bash "$SCRIPT_DIR/configure_network_sharing.sh"

echo "======================================"
echo "Configuring NFS..."
bash "$SCRIPT_DIR/configure_nfs.sh"

echo "======================================"
echo "Configuring Lmod..."
bash "$SCRIPT_DIR/configure_lmod.sh"

echo "======================================"
echo "Installing modulefiles..."
bash "$SCRIPT_DIR/install_modulefiles.sh"

echo "======================================"
echo "Configuring Munge..."
bash "$SCRIPT_DIR/configure_munge.sh"

echo "======================================"
echo "Configuring Slurm controller..."
bash "$SCRIPT_DIR/configure_slurm.sh"

echo "======================================"
echo "Installing Prometheus..."
bash "$SCRIPT_DIR/install_prometheus.sh"

echo "======================================"
echo "Installing Grafana..."
bash "$SCRIPT_DIR/install_grafana.sh"

echo "======================================"
echo "Installing Slurm examples..."
bash "$SCRIPT_DIR/install_slurm_examples.sh"

echo "======================================"
echo " Master-node configuration complete"
echo "======================================"