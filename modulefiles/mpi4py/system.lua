help([[
mpi4py system installation.

This module provides Python bindings for MPI.
Requires the system Python installation.
]])

whatis("Name: mpi4py")
whatis("Version: System")
whatis("Description: Python bindings for MPI")

depends_on("python/3")

setenv("MPI4PY_AVAILABLE", "true")