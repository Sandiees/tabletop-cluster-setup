#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$EUID" -ne 0 ]]; then
    echo "Please run with sudo:"
    echo "  sudo bash setup.sh master"
    echo "  sudo bash setup.sh compute"
    exit 1
fi

ROLE="${1:-}"

case "$ROLE" in
    master)
        bash "$SCRIPT_DIR/scripts/master/setup.sh"
        ;;
    compute)
        bash "$SCRIPT_DIR/scripts/compute/setup.sh"
        ;;
    *)
        echo "Usage: sudo bash setup.sh {master|compute}"
        exit 1
        ;;
esac