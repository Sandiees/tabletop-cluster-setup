#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

DATASOURCE_SOURCE="$REPO_DIR/config/master/grafana/provisioning/datasources/prometheus.yml"
DATASOURCE_DEST="/etc/grafana/provisioning/datasources/prometheus.yml"

echo "Installing Grafana..."

apt install -y wget

mkdir -p /etc/apt/keyrings

wget -q -O /etc/apt/keyrings/grafana.asc \
    https://apt.grafana.com/gpg-full.key

chmod 0644 /etc/apt/keyrings/grafana.asc

cat > /etc/apt/sources.list.d/grafana.list <<EOF
deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main
EOF

apt update
apt install -y grafana

if [[ ! -f "$DATASOURCE_SOURCE" ]]; then
    echo "ERROR: Could not find $DATASOURCE_SOURCE"
    exit 1
fi

mkdir -p /etc/grafana/provisioning/datasources

install -o root -g root -m 0644 \
    "$DATASOURCE_SOURCE" \
    "$DATASOURCE_DEST"

systemctl enable --now grafana-server
systemctl restart grafana-server

echo "Grafana installation complete."