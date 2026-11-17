#!/bin/bash
set -euo pipefail

echo "Updating package lists..."
apt update

echo "Installing common packages..."

apt install -y \
    python3 \
    python3-venv \
    python3-pip \
    python3-psutil \
    openmpi-bin \
    libopenmpi-dev \
    lmod \
    slurm-wlm \
    munge \
    python3-mpi4py \
    python3-joblib \
    python3-sklearn

echo "Common package installation complete."