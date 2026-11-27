#!/bin/bash
#SBATCH --job-name=mnist-training
#SBATCH --output=logs/train-%j.out
#SBATCH --error=logs/train-%j.err
#SBATCH --time=00:05:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M

set -e

cd "/shared/examples/slurm/mnist"

# Limit numerical libraries to the CPUs allocated by Slurm.
export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export OPENBLAS_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export MKL_NUM_THREADS="$SLURM_CPUS_PER_TASK"

echo "Job ID: $SLURM_JOB_ID"
echo "Allocated CPUs: $SLURM_CPUS_PER_TASK"
echo "Node: $SLURMD_NODENAME"
echo "Start time: $(date)"

python train_model.py

echo "End time: $(date)"