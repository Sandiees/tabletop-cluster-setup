help([[
Open MPI system installation.

This module provides access to the system Open MPI installation.
]])

whatis("Name: Open MPI")
whatis("Version: System")
whatis("Description: System Open MPI installation")

setenv("MPIEXEC", "/usr/bin/mpirun")
setenv("MPICC", "/usr/bin/mpicc")