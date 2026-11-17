#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG_SOURCE="$REPO_DIR/config/master/prometheus.yml"
CONFIG_DEST="/etc/prometheus/prometheus.yml"

echo "Installing Prometheus and Node Exporter..."

apt install -y prometheus prometheus-node-exporter

if [[ ! -f "$CONFIG_SOURCE" ]]; then
    echo "ERROR: Could not find $CONFIG_SOURCE"
    exit 1
fi

echo "Validating Prometheus configuration..."

promtool check config "$CONFIG_SOURCE"

install -o root -g root -m 0644 "$CONFIG_SOURCE" "$CONFIG_DEST"

systemctl enable --now prometheus-node-exporter
systemctl enable --now prometheus

systemctl restart prometheus-node-exporter
systemctl restart prometheus

echo "Prometheus configuration complete."