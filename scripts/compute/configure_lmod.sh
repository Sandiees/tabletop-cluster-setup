#!/bin/bash
set -euo pipefail

MODULE_DIR="/shared/modulefiles"

install -d -m 0755 "$MODULE_DIR"

cat > /etc/profile.d/z99_cluster_modules.sh <<'EOF'
if [ -d /shared/modulefiles ]; then
    export MODULEPATH="/shared/modulefiles${MODULEPATH:+:$MODULEPATH}"
fi
EOF

chmod 0644 /etc/profile.d/z99_cluster_modules.sh

echo "Lmod module path configured."