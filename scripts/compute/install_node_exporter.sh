#!/bin/bash
set -euo pipefail

apt-get install -y prometheus-node-exporter

systemctl enable prometheus-node-exporter
systemctl restart prometheus-node-exporter

if ! systemctl is-active --quiet prometheus-node-exporter; then
    echo "ERROR: Node Exporter did not start."
    exit 1
fi

echo "Node Exporter is running on port 9100."