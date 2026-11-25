#!/bin/bash
set -euo pipefail

echo "Configuring master network sharing..."

# Check that NetworkManager is installed and running.
if ! systemctl is-active --quiet NetworkManager; then
    echo "ERROR: NetworkManager is not running."
    exit 1
fi

# Check interfaces.
if ! ip link show wlan0 >/dev/null 2>&1; then
    echo "ERROR: Wi-Fi interface wlan0 not found."
    exit 1
fi

if ! ip link show eth0 >/dev/null 2>&1; then
    echo "ERROR: Ethernet interface eth0 not found."
    exit 1
fi

# Find the active Ethernet connection profile.
ETH_CONN="$(nmcli -t -f NAME,DEVICE connection show --active |
    awk -F: '$2 == "eth0" {print $1; exit}')"

if [[ -z "$ETH_CONN" ]]; then
    echo "ERROR: No active connection found for eth0."
    echo "Connect the Ethernet interface before running this script."
    exit 1
fi

echo "Configuring connection: $ETH_CONN"

# Configure Ethernet as a shared connection.
nmcli connection modify "$ETH_CONN" \
    connection.interface-name eth0 \
    connection.autoconnect yes \
    ipv4.method shared \
    ipv4.addresses 10.42.0.1/24 \
    ipv6.method disabled

# Activate the connection.
nmcli connection up "$ETH_CONN"

# Verify the address.
if ! ip -4 addr show eth0 | grep -q "10.42.0.1/24"; then
    echo "ERROR: Ethernet address configuration failed."
    exit 1
fi

# Verify IP forwarding.
if [[ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]]; then
    echo "ERROR: IP forwarding is not enabled."
    exit 1
fi

echo
echo "Network sharing configured successfully."
echo "Master Ethernet IP: 10.42.0.1"
echo "Cluster network: 10.42.0.0/24"
echo "Internet gateway: Wi-Fi"
