#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

SOURCE_DIR="$REPO_DIR/examples/slurm"
DEST_DIR="/shared/examples/slurm"

echo "Installing Slurm examples..."

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: Examples directory not found: $SOURCE_DIR"
    exit 1
fi

# Create the destination directory.
install -d -o root -g root -m 0755 "$DEST_DIR"

# Copy the repository examples.
cp -a "$SOURCE_DIR/." "$DEST_DIR/"

# Make the examples readable by all users.
find "$DEST_DIR" -type d -exec chmod 0755 {} \;
find "$DEST_DIR" -type f -exec chmod 0644 {} \;

chown -R root:root "$DEST_DIR"

echo "Slurm examples installed in $DEST_DIR"