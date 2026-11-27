#!/bin/bash
set -euo pipefail

INTERFACE="${1:-}"
ACTION="${2:-}"
CONNECTION_ID="${CONNECTION_ID:-}"

# Only manage the firewall for the master's Wi-Fi interface.
[[ "$INTERFACE" == "wlan0" ]] || exit 0

case "$ACTION" in
    up)
        if [[ "$CONNECTION_ID" == "Pi-Cluster" ]]; then
            logger -t pi-cluster-wifi "Pi-Cluster AP is up; enabling client firewall."
            systemctl start pi-cluster-wifi-firewall.service
        else
            logger -t pi-cluster-wifi "Development Wi-Fi is active; disabling AP firewall."
            systemctl stop pi-cluster-wifi-firewall.service || true
        fi
        ;;
    down)
        logger -t pi-cluster-wifi "wlan0 connection is down; disabling AP firewall."
        systemctl stop pi-cluster-wifi-firewall.service || true
        ;;
esac

exit 0
