#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

GRAFANA_CONFIG="$REPO_DIR/config/master/grafana"
PROVISIONING_DIR="/etc/grafana/provisioning"
DASHBOARD_DIR="/var/lib/grafana/dashboards"

echo "Installing Grafana..."

# Install prerequisites
apt install -y wget

# Add Grafana repository
mkdir -p /etc/apt/keyrings

wget -q -O /etc/apt/keyrings/grafana.asc \
    https://apt.grafana.com/gpg-full.key

chmod 0644 /etc/apt/keyrings/grafana.asc

cat > /etc/apt/sources.list.d/grafana.list <<EOF
deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main
EOF

apt update
apt install -y grafana

echo "Installing Grafana provisioning configuration..."

# Install Prometheus datasource
install -d "$PROVISIONING_DIR/datasources"

install -o root -g grafana -m 0640 \
    "$GRAFANA_CONFIG/provisioning/datasources/prometheus.yml" \
    "$PROVISIONING_DIR/datasources/prometheus.yml"

# Install dashboard provisioning configuration
install -d "$PROVISIONING_DIR/dashboards"

install -o root -g grafana -m 0640 \
    "$GRAFANA_CONFIG/provisioning/dashboards/dashboards.yml" \
    "$PROVISIONING_DIR/dashboards/dashboards.yml"

# Install dashboard JSON files
mkdir -p "$DASHBOARD_DIR"

cp -a "$GRAFANA_CONFIG/dashboards/." "$DASHBOARD_DIR/"

chown -R root:grafana "$DASHBOARD_DIR"
find "$DASHBOARD_DIR" -type d -exec chmod 0755 {} \;
find "$DASHBOARD_DIR" -type f -exec chmod 0644 {} \;

# Validate dashboard JSON files
while IFS= read -r -d '' file; do
    python3 -m json.tool "$file" > /dev/null
    echo "Validated: $file"
done < <(find "$DASHBOARD_DIR" -name '*.json' -print0)

# Enable and start Grafana
systemctl enable --now grafana-server
systemctl restart grafana-server

echo "Grafana installation complete."