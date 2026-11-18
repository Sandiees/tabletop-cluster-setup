#!/bin/bash
set -euo pipefail

echo "Configuring Lmod..."

apt install -y lmod

MODULE_PATH="/shared/modulefiles"
PROFILE_FILE="/etc/profile.d/z99_cluster_modules.sh"

mkdir -p "$MODULE_PATH"

cat > "$PROFILE_FILE" <<'EOF'
# Raspberry Pi cluster modulefiles
export MODULEPATH="/shared/modulefiles${MODULEPATH:+:$MODULEPATH}"
EOF

chmod 0644 "$PROFILE_FILE"

echo "Lmod configured."
echo "Module path: $MODULE_PATH"