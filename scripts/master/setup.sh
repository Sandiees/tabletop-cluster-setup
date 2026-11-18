#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo " Starting master-node configuration"
echo "======================================"

echo "[1/8] Installing common packages..."
bash "$SCRIPT_DIR/../common/install_packages.sh"

echo "[2/8] Configuring Lmod..."
bash "$SCRIPT_DIR/configure_lmod.sh"

echo "[3/8] Installing modulefiles..."
bash "$SCRIPT_DIR/install_modulefiles.sh"

echo "[4/8] Configuring Munge..."
bash "$SCRIPT_DIR/configure_munge.sh"

echo "[5/8] Configuring Slurm controller..."
bash "$SCRIPT_DIR/configure_slurm.sh"

echo "[6/8] Installing Prometheus..."
bash "$SCRIPT_DIR/install_prometheus.sh"

echo "[7/8] Installing Grafana..."
bash "$SCRIPT_DIR/install_grafana.sh"

echo "[8/8] Installing Slurm examples..."
bash "$SCRIPT_DIR/install_slurm_examples.sh"

echo "======================================"
echo " Master-node configuration complete"
echo "======================================"