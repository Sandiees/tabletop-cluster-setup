#!/bin/bash
set -euo pipefail

HOSTS_FILE="/etc/hosts"
TEMPLATE_FILE="/etc/cloud/templates/hosts.debian.tmpl"

HOST_ENTRIES=(
    "10.42.0.1 master-node"
    "10.42.0.2 compute-node-01"
    "10.42.0.3 compute-node-02"
    "10.42.0.4 compute-node-03"
    "10.42.0.5 compute-node-04"
)

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run this script as root."
    exit 1
fi

echo "Configuring cluster hostname resolution..."

# Update the cloud-init template so entries survive reboots.
if [[ -f "$TEMPLATE_FILE" ]]; then
    sed -i '/# BEGIN TABLETOP CLUSTER HOSTS/,/# END TABLETOP CLUSTER HOSTS/d' "$TEMPLATE_FILE"

    {
        echo "# BEGIN TABLETOP CLUSTER HOSTS"
        printf '%s\n' "${HOST_ENTRIES[@]}"
        echo "# END TABLETOP CLUSTER HOSTS"
    } >> "$TEMPLATE_FILE"

    echo "Updated cloud-init hosts template."
else
    echo "WARNING: Cloud-init hosts template not found: $TEMPLATE_FILE"
fi

# Update the current /etc/hosts file as well.
sed -i '/# BEGIN TABLETOP CLUSTER HOSTS/,/# END TABLETOP CLUSTER HOSTS/d' "$HOSTS_FILE"

{
    echo "# BEGIN TABLETOP CLUSTER HOSTS"
    printf '%s\n' "${HOST_ENTRIES[@]}"
    echo "# END TABLETOP CLUSTER HOSTS"
} >> "$HOSTS_FILE"

echo "Cluster hostname resolution configured."
