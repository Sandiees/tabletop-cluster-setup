#!/bin/bash
#SBATCH --job-name=cpu-example
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:02:00
#SBATCH --mem=256M
#SBATCH --output=cpu-%j.out

set -euo pipefail

echo "Starting CPU example"
echo "Running on: $(hostname)"
echo "Allocated CPUs: $SLURM_CPUS_PER_TASK"

python3 - <<'PY'
import time

def is_prime(number):
    if number < 2:
        return False

    for divisor in range(2, int(number**0.5) + 1):
        if number % divisor == 0:
            return False

    return True

start = time.time()
limit = 200_000

primes = [number for number in range(2, limit) if is_prime(number)]

print(f"Found {len(primes)} primes below {limit}")
print(f"Largest prime: {primes[-1]}")
print(f"Calculation took {time.time() - start:.2f} seconds")
PY

echo "CPU example finished"