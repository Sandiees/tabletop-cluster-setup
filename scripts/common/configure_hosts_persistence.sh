#!/bin/bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run this script as root (using sudo)."
    exit 1
fi

CLOUD_INIT_CONFIG="/etc/cloud/cloud.cfg.d/99-disable-hosts-management.cfg"

echo "Disabling cloud-init management of /etc/hosts..."

install -d -m 0755 /etc/cloud/cloud.cfg.d

cat > "$CLOUD_INIT_CONFIG" <<'EOF'
# Let the cluster setup scripts manage /etc/hosts.
manage_etc_hosts: false
EOF

chmod 0644 "$CLOUD_INIT_CONFIG"

echo "Cloud-init will no longer regenerate /etc/hosts."
