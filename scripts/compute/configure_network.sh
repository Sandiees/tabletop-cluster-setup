#!/bin/bash
set -euo pipefail

HOSTNAME=$(hostname)

case "$HOSTNAME" in
    compute-node-01) IP="10.42.0.2" ;;
    compute-node-02) IP="10.42.0.3" ;;
    compute-node-03) IP="10.42.0.4" ;;
    compute-node-04) IP="10.42.0.5" ;;
    *)
        echo "Unknown compute node: $HOSTNAME"
        exit 1
        ;;
esac

CONNECTION=$(
    nmcli -t -f NAME,DEVICE connection show --active |
    awk -F: '$NF == "eth0" {
        sub(/:eth0$/, "")
        print
        exit
    }'
)

if [[ -z "$CONNECTION" ]]; then
    echo "No active NetworkManager connection found for eth0."
    exit 1
fi

nmcli connection modify "$CONNECTION" \
    ipv4.method manual \
    ipv4.addresses "$IP/24" \
    ipv4.gateway 10.42.0.1 \
    ipv4.dns 10.42.0.1 \
    ipv6.method disabled \
    connection.autoconnect yes

nmcli connection up "$CONNECTION"

echo "Configured $HOSTNAME with IP $IP"