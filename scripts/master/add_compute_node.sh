
#!/bin/bash
set -euo pipefail

MASTER_IP="10.42.0.1"
REMOTE_USER="admin"
REMOTE_REPO="/opt/tabletop-cluster-setup"
SSH_PORT=22
DISCOVERY_TIMEOUT=180
RECONNECT_TIMEOUT=180

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo."
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: sudo $0 compute-node-01"
    exit 1
fi

NODE="$1"

case "$NODE" in
    compute-node-01) NODE_IP="10.42.0.2" ;;
    compute-node-02) NODE_IP="10.42.0.3" ;;
    compute-node-03) NODE_IP="10.42.0.4" ;;
    compute-node-04) NODE_IP="10.42.0.5" ;;
    *)
        echo "Unknown compute node: $NODE"
        exit 1
        ;;
esac

# Use the SSH identity belonging to the user who invoked sudo.
SSH_USER="${SUDO_USER:-admin}"
SSH_HOME="$(getent passwd "$SSH_USER" | cut -d: -f6)"
SSH_KEY="$SSH_HOME/.ssh/id_ed25519"
KNOWN_HOSTS="$SSH_HOME/.ssh/known_hosts"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MUNGE_KEY="/etc/munge/munge.key"

if [[ ! -f "$SSH_KEY" ]]; then
    echo "SSH private key not found: $SSH_KEY"
    exit 1
fi

if [[ ! -f "$MUNGE_KEY" ]]; then
    echo "Master Munge key not found: $MUNGE_KEY"
    exit 1
fi

if [[ ! -f "$REPO_DIR/scripts/compute/setup.sh" ]]; then
    echo "Compute setup script not found in $REPO_DIR"
    exit 1
fi

if ! command -v rsync >/dev/null; then
    echo "Please install rsync on the master."
    exit 1
fi

SSH_OPTIONS=(
    -i "$SSH_KEY"
    -p "$SSH_PORT"
    -o BatchMode=yes
    -o ConnectTimeout=5
    -o StrictHostKeyChecking=accept-new
    -o UserKnownHostsFile="$KNOWN_HOSTS"
)

ssh_admin() {
    runuser -u "$SSH_USER" -- \
        ssh "${SSH_OPTIONS[@]}" "$REMOTE_USER@$1" "${@:2}"
}

echo "======================================"
echo " Adding compute node: $NODE"
echo " Permanent IP: $NODE_IP"
echo "======================================"

# ------------------------------------------------
# 1. Discover the node using its temporary DHCP IP
# ------------------------------------------------

echo "Waiting for $NODE.local..."

DISCOVERY_IP=""
DEADLINE=$((SECONDS + DISCOVERY_TIMEOUT))

while (( SECONDS < DEADLINE )); do
    DISCOVERY_IP="$(
        getent ahostsv4 "$NODE.local" 2>/dev/null |
        awk 'NR == 1 {print $1}'
    )"

    if [[ -n "$DISCOVERY_IP" ]] &&
       ssh_admin "$DISCOVERY_IP" true >/dev/null 2>&1; then
        break
    fi

    DISCOVERY_IP=""
    sleep 3
done

if [[ -z "$DISCOVERY_IP" ]]; then
    echo "Could not discover $NODE or connect using SSH."
    echo "Check its hostname, SSH configuration and network connection."
    exit 1
fi

echo "Found $NODE at $DISCOVERY_IP."

# ------------------------------------------------
# 2. Configure its permanent static IP
# ------------------------------------------------

echo "Configuring static IP $NODE_IP..."

# Save the static configuration first.
# Schedule activation separately so the SSH session can exit
# before NetworkManager interrupts the existing connection.

ssh_admin "$DISCOVERY_IP" \
    "sudo -n bash -s -- '$NODE_IP' '$MASTER_IP'" <<'REMOTE'
set -euo pipefail

NODE_IP="$1"
MASTER_IP="$2"

if ! command -v nmcli >/dev/null; then
    echo "NetworkManager (nmcli) is not installed."
    exit 1
fi

CONNECTION="$(
    nmcli -t -f NAME,DEVICE connection show --active |
    awk -F: '$NF == "eth0" {
        sub(/:eth0$/, "")
        print
        exit
    }'
)"

if [[ -z "$CONNECTION" ]]; then
    echo "No active NetworkManager connection found for eth0."
    nmcli device status
    exit 1
fi

nmcli connection modify "$CONNECTION" \
    connection.interface-name eth0 \
    connection.autoconnect yes \
    ipv4.method manual \
    ipv4.addresses "$NODE_IP/24" \
    ipv4.gateway "$MASTER_IP" \
    ipv4.dns "$MASTER_IP" \
    ipv6.method disabled

echo "Static configuration saved."

# Activate the connection after this SSH command has returned.
systemd-run \
    --on-active=2s \
    --collect \
    /usr/bin/nmcli connection up "$CONNECTION"

echo "Network reconfiguration scheduled."
REMOTE

# ------------------------------------------------
# 3. Reconnect using the permanent IP
# ------------------------------------------------

echo "Waiting for SSH at $NODE_IP..."

CONNECTED=0
DEADLINE=$((SECONDS + RECONNECT_TIMEOUT))

while (( SECONDS < DEADLINE )); do
    if ssh_admin "$NODE_IP" true >/dev/null 2>&1; then
        CONNECTED=1
        break
    fi

    sleep 3
done

if [[ "$CONNECTED" -ne 1 ]]; then
    echo "Could not reconnect to $NODE at $NODE_IP."
    echo "Stopping before software installation."
    exit 1
fi

echo "Static IP connection verified."

# ------------------------------------------------
# 4. Prepare a staging directory outside /home
# ------------------------------------------------

echo "Preparing remote repository directory..."

ssh_admin "$NODE_IP" \
    "sudo -n install -d -o admin -g admin -m 0755 '$REMOTE_REPO'"

# ------------------------------------------------
# 5. Copy repository to the compute node
# ------------------------------------------------

echo "Copying repository..."

runuser -u "$SSH_USER" -- rsync -az \
    --delete \
    --exclude='.git/' \
    --exclude='__pycache__/' \
    -e "ssh -i $SSH_KEY -p $SSH_PORT -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$KNOWN_HOSTS" \
    "$REPO_DIR/" \
    "$REMOTE_USER@$NODE_IP:$REMOTE_REPO/"

# ------------------------------------------------
# 6. Install packages before distributing Munge key
# ------------------------------------------------

echo "Installing required packages..."

ssh_admin "$NODE_IP" \
    "sudo -n bash '$REMOTE_REPO/scripts/common/install_packages.sh'"

# ------------------------------------------------
# 7. Distribute the master's Munge key
# ------------------------------------------------

echo "Distributing Munge key..."

TEMP_KEY="$(mktemp)"
trap 'rm -f "$TEMP_KEY"' EXIT

install -o "$SSH_USER" -g "$(id -gn "$SSH_USER")" \
    -m 0600 "$MUNGE_KEY" "$TEMP_KEY"

SCP_OPTIONS=(
    -i "$SSH_KEY"
    -P "$SSH_PORT"
    -o BatchMode=yes
    -o ConnectTimeout=5
    -o StrictHostKeyChecking=accept-new
    -o UserKnownHostsFile="$KNOWN_HOSTS"
)

runuser -u "$SSH_USER" -- \
    scp "${SCP_OPTIONS[@]}" "$TEMP_KEY" \
    "$REMOTE_USER@$NODE_IP:/tmp/munge.key"

ssh_admin "$NODE_IP" \
    "sudo -n install -o munge -g munge -m 0400 /tmp/munge.key /etc/munge/munge.key && \
     rm -f /tmp/munge.key"

rm -f "$TEMP_KEY"
trap - EXIT

# ------------------------------------------------
# 8. Run the existing compute setup
# ------------------------------------------------

echo "Running compute-node setup..."

ssh_admin "$NODE_IP" \
    "sudo -n bash '$REMOTE_REPO/scripts/compute/setup.sh'"

# ------------------------------------------------
# 9. Verify the node
# ------------------------------------------------

echo
echo "Checking node services..."

ssh_admin "$NODE_IP" \
    "systemctl is-active munge && \
     systemctl is-enabled slurmd && \
     mountpoint -q /shared && \
     mountpoint -q /home"

echo
echo "======================================"
echo " Compute node setup completed!"
echo " Node: $NODE"
echo " IP:   $NODE_IP"
echo "======================================"
