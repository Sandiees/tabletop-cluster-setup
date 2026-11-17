#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo."
    exit 1
fi

ROLE="${1:-}"

case "$ROLE" in
    master)
        bash "$REPO_DIR/scripts/master/setup.sh"
        ;;
    compute)
        echo "Compute-node setup has not been implemented yet."
        exit 1
        ;;
    *)
        echo "Usage: sudo bash setup.sh {master|compute}"
        exit 1
        ;;
esac