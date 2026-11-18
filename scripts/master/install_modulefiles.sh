#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

SOURCE_DIR="$REPO_DIR/modulefiles"
DEST_DIR="/shared/modulefiles"
MANIFEST="$SOURCE_DIR/manifest.tsv"

echo "Installing and validating Lmod modulefiles..."

if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: Module manifest not found: $MANIFEST"
    exit 1
fi

if ! command -v lmod >/dev/null 2>&1; then
    echo "ERROR: Lmod executable not found."
    echo "Check installation with: dpkg -L lmod"
    exit 1
fi

# First validate all software installations.
while IFS='|' read -r module_file check_command; do
    [[ -z "${module_file:-}" || "$module_file" == \#* ]] && continue

    if [[ -z "${check_command:-}" ]]; then
        echo "ERROR: Missing validation command for $module_file"
        exit 1
    fi

    if [[ ! -f "$SOURCE_DIR/$module_file" ]]; then
        echo "ERROR: Modulefile missing: $module_file"
        exit 1
    fi

    echo "Checking software for $module_file..."

    if ! bash -c "$check_command"; then
        echo "ERROR: Software check failed for $module_file"
        echo "Required software may not be installed."
        exit 1
    fi
done < "$MANIFEST"

echo "All software installation checks passed."

# Install modulefiles only after the software checks succeed.
mkdir -p "$DEST_DIR"

cp -a "$SOURCE_DIR/." "$DEST_DIR/"

chown -R root:root "$DEST_DIR"
find "$DEST_DIR" -type d -exec chmod 0755 {} \;
find "$DEST_DIR" -type f -exec chmod 0644 {} \;

# Check that Lmod can evaluate every installed modulefile.
while IFS='|' read -r module_file check_command; do
    [[ -z "${module_file:-}" || "$module_file" == \#* ]] && continue

    module_name="${module_file%.lua}"
    module_name="${module_name//\//\/}"

    echo "Validating Lmod module: $module_name"

    if ! MODULEPATH="$DEST_DIR" lmod bash load "$module_name" >/dev/null; then
        echo "ERROR: Lmod could not load $module_name"
        exit 1
    fi
done < "$MANIFEST"

echo "All modulefiles passed validation."
echo "Installed in: $DEST_DIR"
