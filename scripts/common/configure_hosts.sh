#!/bin/bash
set -euo pipefail

HOSTS_FILE="/etc/hosts"

HOST_ENTRIES=(
    "10.42.0.1 master-node"
    "10.42.0.2 compute-node-01"
    "10.42.0.3 compute-node-02"
    "10.42.0.4 compute-node-03"
    "10.42.0.5 compute-node-04"
)

echo "Configuring cluster hostname resolution..."

# Remove any previous entries managed by this script.
sed -i '/# BEGIN TABLETOP CLUSTER HOSTS/,/# END TABLETOP CLUSTER HOSTS/d' "$HOSTS_FILE"

# Add the cluster host entries.
{
    echo "# BEGIN TABLETOP CLUSTER HOSTS"
    printf '%s\n' "${HOST_ENTRIES[@]}"
    echo "# END TABLETOP CLUSTER HOSTS"
} >> "$HOSTS_FILE"

echo "Cluster hostname resolution configured."