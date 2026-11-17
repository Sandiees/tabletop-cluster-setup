#!/bin/bash
#SBATCH --job-name=python-example
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:02:00
#SBATCH --mem=256M
#SBATCH --output=python-%j.out

set -euo pipefail

echo "Starting Python example"
echo "Running on: $(hostname)"

python3 - <<'PY'
import random
import time

samples = 1_000_000
inside_circle = 0

start = time.time()

for _ in range(samples):
    x = random.random()
    y = random.random()

    if x*x + y*y <= 1:
        inside_circle += 1

pi_estimate = 4 * inside_circle / samples

print(f"Samples: {samples}")
print(f"Estimated pi: {pi_estimate}")
print(f"Elapsed time: {time.time() - start:.2f} seconds")
PY

echo "Python example finished"