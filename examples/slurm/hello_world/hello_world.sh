#!/bin/bash
#SBATCH --job-name=hello-world
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:01:00
#SBATCH --mem=128M
#SBATCH --output=hello-%j.out

set -euo pipefail

echo "Hello from Slurm!"
echo "Job ID:       $SLURM_JOB_ID"
echo "Job name:     $SLURM_JOB_NAME"
echo "Node list:    $SLURM_JOB_NODELIST"
echo "Number tasks: $SLURM_NTASKS"
echo "Hostname:     $(hostname)"
echo "Date:         $(date)"