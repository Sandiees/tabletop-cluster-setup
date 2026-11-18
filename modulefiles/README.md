# Cluster Lmod modulefiles

This directory contains the Lmod modulefiles available on the Raspberry Pi cluster.

Modulefiles are deployed to:

```text
/shared/modulefiles/
```

## Available modules

| Module | Description |
|---|---|
| `python/3` | System Python 3 |
| `openmpi/system` | System Open MPI installation |
| `mpi4py/system` | Python MPI bindings |

## Adding a module

To add a new module:

1. Create a Lua modulefile in the appropriate directory.
2. Add an entry to `manifest.tsv`.
3. Add the corresponding software installation to the appropriate installation script.
4. Test the module on the master and compute nodes.

For example, a modulefile at:

```text
python/3.lua
```

is loaded using:

```bash
module load python/3
```

## Software validation

The `manifest.tsv` file associates each modulefile with a command that checks whether its required software is installed.

The master installation script runs these checks before deploying the modulefiles.

Modulefiles should only be added when their corresponding software is installed on the cluster nodes.
