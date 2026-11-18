#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo " Starting master-node configuration"
echo "======================================"

echo "[1/9] Installing common packages..."
bash "$SCRIPT_DIR/../common/install_packages.sh"

# echo "[2/9] Configuring NFS..."
# bash "$SCRIPT_DIR/configure_nfs.sh"
echo "[2/9] Skipping NFS configuration. Not implemented yet."

echo "[3/9] Configuring Lmod..."
bash "$SCRIPT_DIR/configure_lmod.sh"

echo "[4/9] Installing modulefiles..."
bash "$SCRIPT_DIR/install_modulefiles.sh"

echo "[5/9] Configuring Munge..."
bash "$SCRIPT_DIR/configure_munge.sh"

echo "[6/9] Configuring Slurm controller..."
bash "$SCRIPT_DIR/configure_slurm.sh"

echo "[7/9] Installing Prometheus..."
bash "$SCRIPT_DIR/install_prometheus.sh"

echo "[8/9] Installing Grafana..."
bash "$SCRIPT_DIR/install_grafana.sh"

echo "[9/9] Installing Slurm examples..."
bash "$SCRIPT_DIR/install_slurm_examples.sh"

echo "======================================"
echo " Master-node configuration complete"
echo "======================================"