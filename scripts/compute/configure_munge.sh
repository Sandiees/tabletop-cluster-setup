#!/bin/bash
set -euo pipefail

MUNGE_KEY="/etc/munge/munge.key"

if [[ ! -f "$MUNGE_KEY" ]]; then
    echo "ERROR: Munge key not found at $MUNGE_KEY"
    echo "Copy the master's Munge key to this node before continuing."
    exit 1
fi

chown munge:munge "$MUNGE_KEY"
chmod 0400 "$MUNGE_KEY"

systemctl enable munge
systemctl restart munge

if ! munge -n | unmunge >/dev/null; then
    echo "ERROR: Munge authentication test failed."
    exit 1
fi

echo "Munge configured successfully."