#!/bin/bash
set -euo pipefail

KEY_FILE="/etc/munge/munge.key"

echo "Configuring Munge..."

if ! id munge >/dev/null 2>&1; then
    echo "ERROR: Munge user does not exist. Was the munge package installed?"
    exit 1
fi

mkdir -p /etc/munge
chown munge:munge /etc/munge
chmod 0700 /etc/munge

if [[ ! -f "$KEY_FILE" ]]; then
    echo "Generating new Munge key..."

    umask 077
    dd if=/dev/urandom of="$KEY_FILE" bs=1024 count=1 status=none

    chown munge:munge "$KEY_FILE"
    chmod 0400 "$KEY_FILE"
else
    echo "Existing Munge key found. Keeping it."
    chown munge:munge "$KEY_FILE"
    chmod 0400 "$KEY_FILE"
fi

systemctl enable --now munge

echo "Testing Munge..."
munge -n | unmunge

echo "Munge configuration complete."