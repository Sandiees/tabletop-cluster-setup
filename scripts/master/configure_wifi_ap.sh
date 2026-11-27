#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AP_CONNECTION="Pi-Cluster"
DEV_CONNECTION="Your-Wi-Fi-Name"
WIFI_INTERFACE="wlan0"
AP_SSID="Pi-Cluster"
AP_ADDRESS="192.168.50.1/24"

echo "Configuring the student Wi-Fi access point..."

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script as root (using sudo)."
    exit 1
fi

if ! systemctl is-active --quiet NetworkManager; then
    echo "ERROR: NetworkManager is not running."
    exit 1
fi

if ! ip link show "$WIFI_INTERFACE" >/dev/null 2>&1; then
    echo "ERROR: Wi-Fi interface $WIFI_INTERFACE was not found."
    exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
    echo "ERROR: nmcli is not installed."
    exit 1
fi

# NetworkManager's shared mode supplies DHCP and DNS to AP clients.
# nftables is used to prevent those clients from forwarding traffic
# to the Ethernet cluster network or any other interface.
apt-get update
apt-get install -y nftables

read -rsp "Enter a WPA2 password for ${AP_SSID} (8-63 characters): " WIFI_PASSWORD
echo
if (( ${#WIFI_PASSWORD} < 8 || ${#WIFI_PASSWORD} > 63 )); then
    echo "ERROR: Wi-Fi passwords must be 8-63 characters."
    unset WIFI_PASSWORD
    exit 1
fi

read -rsp "Confirm Wi-Fi password: " WIFI_PASSWORD_CONFIRM
echo
if [[ "$WIFI_PASSWORD" != "$WIFI_PASSWORD_CONFIRM" ]]; then
    echo "ERROR: Passwords do not match."
    unset WIFI_PASSWORD WIFI_PASSWORD_CONFIRM
    exit 1
fi
unset WIFI_PASSWORD_CONFIRM

# Create the connection if it does not exist; otherwise update it.
if nmcli -t -f NAME connection show | grep -Fxq "$AP_CONNECTION"; then
    echo "Updating existing NetworkManager profile: $AP_CONNECTION"
else
    echo "Creating NetworkManager profile: $AP_CONNECTION"
    nmcli connection add \
        type wifi \
        ifname "$WIFI_INTERFACE" \
        con-name "$AP_CONNECTION" \
        ssid "$AP_SSID"
fi

nmcli connection modify "$AP_CONNECTION" \
    connection.interface-name "$WIFI_INTERFACE" \
    connection.autoconnect yes \
    connection.autoconnect-priority 100 \
    802-11-wireless.mode ap \
    802-11-wireless.band bg \
    802-11-wireless.channel 6 \
    802-11-wireless.ssid "$AP_SSID" \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "$WIFI_PASSWORD" \
    ipv4.method shared \
    ipv4.addresses "$AP_ADDRESS" \
    ipv6.method disabled

unset WIFI_PASSWORD

# Keep the development Wi-Fi profile saved, but prevent it from
# automatically taking wlan0 away from the AP after reboot.
if nmcli -t -f NAME connection show | grep -Fxq "$DEV_CONNECTION"; then
    nmcli connection modify "$DEV_CONNECTION" connection.autoconnect no
    echo "Disabled autoconnect for the saved '$DEV_CONNECTION' profile."
else
    echo "WARNING: '$DEV_CONNECTION' profile was not found."
    echo "The AP profile is configured, but check the development profile name."
fi

# Install the firewall, systemd unit, and NetworkManager dispatcher.
install -D -m 0644 \
    "$REPO_ROOT/config/networking/pi-cluster-wifi-firewall.nft" \
    /etc/pi-cluster-wifi-firewall.nft

install -D -m 0644 \
    "$REPO_ROOT/config/systemd/pi-cluster-wifi-firewall.service" \
    /etc/systemd/system/pi-cluster-wifi-firewall.service

install -D -m 0755 \
    "$SCRIPT_DIR/wifi_ap_dispatcher.sh" \
    /etc/NetworkManager/dispatcher.d/90-pi-cluster-wifi-firewall

# Validate the nftables file without applying it.
nft -c -f /etc/pi-cluster-wifi-firewall.nft

systemctl daemon-reload

# Do not activate the AP here. This is deliberate: the setup may be
# running over the current Wi-Fi SSH connection. The dispatcher will
# enable the firewall when Pi-Cluster becomes active.
ACTIVE_WLAN_CONNECTION="$(
    nmcli -g GENERAL.CONNECTION device show "$WIFI_INTERFACE" 2>/dev/null || true
)"

if [[ "$ACTIVE_WLAN_CONNECTION" == "$AP_CONNECTION" ]]; then
    systemctl start pi-cluster-wifi-firewall.service
else
    systemctl stop pi-cluster-wifi-firewall.service || true
fi

echo
echo "Student Wi-Fi access point configured."
echo "  SSID:       $AP_SSID"
echo "  Master IP:  ${AP_ADDRESS%/*}"
echo "  DHCP:       Provided by NetworkManager"
echo "  Firewall:   Allows DHCP, DNS and SSH to the master only"
echo
echo "The AP has NOT been activated now, so the current Wi-Fi SSH session"
echo "should remain connected."
echo
echo "Reboot the master to start the Pi-Cluster access point automatically:"
echo "  sudo reboot"
echo
echo "After reboot, students can connect to '$AP_SSID' and SSH to:"
echo "  ssh admin@${AP_ADDRESS%/*}"
