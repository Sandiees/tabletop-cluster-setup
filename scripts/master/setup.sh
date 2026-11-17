#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo " Starting master-node configuration"
echo "======================================"

echo "[1/6] Installing common packages..."
bash "$SCRIPT_DIR/../common/install_packages.sh"

echo "[2/6] Configuring Munge..."
bash "$SCRIPT_DIR/configure_munge.sh"

echo "[3/6] Configuring Slurm controller..."
bash "$SCRIPT_DIR/configure_slurm.sh"

echo "[4/6] Installing Prometheus..."
bash "$SCRIPT_DIR/install_prometheus.sh"

echo "[5/6] Installing Grafana..."
bash "$SCRIPT_DIR/install_grafana.sh"

echo "[6/6] Installing Slurm examples..."
bash "$SCRIPT_DIR/install_slurm_examples.sh"

echo "======================================"
echo " Master-node configuration complete"
echo "======================================"