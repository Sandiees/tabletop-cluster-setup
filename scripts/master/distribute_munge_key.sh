#!/bin/bash
set -euo pipefail

KEY_FILE="/etc/munge/munge.key"

COMPUTE_NODES=(
    "compute-node-01"
    "compute-node-02"
    "compute-node-03"
    "compute-node-04"
)

if [[ ! -f "$KEY_FILE" ]]; then
    echo "ERROR: Munge key not found at $KEY_FILE"
    echo "Install Munge and generate a key on the master first."
    exit 1
fi

# Create a temporary copy that the current SSH user can read.
TEMP_KEY=$(mktemp)
REMOTE_KEY="/tmp/munge.key.$USER"

cleanup() {
    rm -f "$TEMP_KEY"
}
trap cleanup EXIT

sudo install -o "$(id -un)" -g "$(id -gn)" -m 600 \
    "$KEY_FILE" "$TEMP_KEY"

for NODE in "${COMPUTE_NODES[@]}"; do
    echo "Distributing Munge key to $NODE..."

    scp "$TEMP_KEY" "$NODE:$REMOTE_KEY"

    ssh -t "$NODE" "
        sudo systemctl stop slurmd || true
        sudo systemctl stop munge || true

        sudo install -o munge -g munge -m 400 \
            '$REMOTE_KEY' /etc/munge/munge.key

        rm -f '$REMOTE_KEY'

        sudo systemctl start munge
        sudo systemctl start slurmd
    "

    echo "Key installed on $NODE."
done

echo "Munge key distribution completed."
