# Slurm examples

These examples demonstrate how to submit and manage jobs using Slurm.

## 1. Check the cluster

Display the available compute nodes:

```bash
sinfo
```

Display your currently queued or running jobs:

```bash
squeue -u "$USER"
```

## 2. Submit a job

Submit a job using `sbatch`:

```bash
sbatch /shared/examples/slurm/hello_world/hello_world.sh
```

Slurm will return a job ID.

## 3. Check your job

Check whether your job is queued or running:

```bash
squeue -u "$USER"
```

When the job has finished, its output will be written to a file in your submission directory. The output filename is specified by the `--output` option in the job script.

For example:

```bash
cat hello-JOBID.out
```

Replace `JOBID` with the actual job ID.

## 4. Cancel a job

Cancel a job using its job ID:

```bash
scancel JOBID
```

## 5. Available examples

### Hello World

A basic job that prints information about the job and the compute node.

```bash
sbatch /shared/examples/slurm/hello_world/hello_world.sh
```

### CPU example

A CPU-intensive task that calculates prime numbers.

```bash
sbatch /shared/examples/slurm/cpu/cpu_job.sh
```

### Python example

A Python Monte Carlo simulation that estimates the value of pi.

```bash
sbatch /shared/examples/slurm/python/python_job.sh
```

### MPI example

A parallel program that starts four MPI processes across two compute nodes.

```bash
sbatch /shared/examples/slurm/mpi/mpi_job.sh
```

The MPI example requires at least two available compute nodes.

## 6. Important notes

- Jobs are submitted with `sbatch`; they do not run immediately unless resources are available.
- The examples are administrator-managed. Copy them to your own directory if you want to modify them.
- Keep your requested CPU cores, memory, and runtime reasonable so other students can use the cluster.