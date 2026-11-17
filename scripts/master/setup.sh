#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo " Starting master-node configuration"
echo "======================================"

echo "[1/5] Installing common packages..."
bash "$SCRIPT_DIR/../common/install_packages.sh"

echo "[2/5] Configuring Munge..."
bash "$SCRIPT_DIR/configure_munge.sh"

echo "[3/5] Configuring Slurm controller..."
bash "$SCRIPT_DIR/configure_slurm.sh"

echo "[4/5] Installing Prometheus..."
bash "$SCRIPT_DIR/install_prometheus.sh"

echo "[5/5] Installing Grafana..."
bash "$SCRIPT_DIR/install_grafana.sh"

echo "======================================"
echo " Master-node configuration complete"
echo "======================================"