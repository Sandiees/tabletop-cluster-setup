#!/bin/bash
#SBATCH --job-name=mpi-example
#SBATCH --partition=compute
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=2
#SBATCH --time=00:02:00
#SBATCH --mem=256M
#SBATCH --output=mpi-%j.out

set -euo pipefail

echo "Starting MPI example"
echo "Allocated nodes: $SLURM_JOB_NODELIST"
echo "Number of tasks: $SLURM_NTASKS"

mpirun -np "$SLURM_NTASKS" \
    python3 /shared/examples/slurm/mpi/mpi_hello.py

echo "MPI example finished"