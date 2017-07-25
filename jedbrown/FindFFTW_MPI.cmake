# - Find FFTW_MPI
# Find the MPI version of the FFTW includes and library
#
#  FFTW_MPI_INCLUDES    - where to find fftw3-mpi.h
#  FFTW_MPI_LIBRARIES[_SHARED,_STATIC]   - List of libraries when using FFTW.
#  FFTW_MPI_FOUND       - True if FFTW_MPI found.
#  FFTW_MPI_IS_SHARED   - True if FFTW_MPI_LIBRARIES points to a shared library

if(FFTW_MPI_INCLUDES)
  # Already in cache, be silent
  set (FFTW_MPI_FIND_QUIETLY TRUE)
endif (FFTW_MPI_INCLUDES)

find_path(FFTW_MPI_INCLUDES fftw3-mpi.h)

find_library(FFTW_MPI_LIBRARIES NAMES fftw3_mpi)
find_library(FFTW_MPI_LIBRARIES_STATIC   NAMES libfftw3_mpi.a)
find_library(FFTW_MPI_LIBRARIES_SHARED   NAMES fftw3_mpi${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_SHARED_LIBRARY_PREFIX}fftw3_mpi${CMAKE_SHARED_LIBRARY_SUFFIX})
mark_as_advanced(FFTW_MPI_LIBRARIES_STATIC FFTW_MPI_LIBRARIES_SHARED)

#prefer shared libraries, but fall back to static
if(FFTW_MPI_LIBRARIES_SHARED)
	set(FFTW_MPI_LIBRARIES ${FFTW_MPI_LIBRARIES_SHARED})
	set(FFTW_MPI_IS_SHARED TRUE)
else()
	set(FFTW_MPI_LIBRARIES ${FFTW_MPI_LIBRARIES_STATIC})
	set(FFTW_MPI_IS_SHARED FALSE)
endif()


# handle the QUIETLY and REQUIRED arguments and set FFTW_FOUND to TRUE if
# all listed variables are TRUE
include (FindPackageHandleStandardArgs)
find_package_handle_standard_args (FFTW_MPI "Could NOT find MPI FFTW.  Please set FFTW_MPI_LIBRARIES and FFTW_MPI_INCLUDES to point to it." FFTW_MPI_LIBRARIES FFTW_MPI_INCLUDES)

mark_as_advanced (FFTW_MPI_LIBRARIES FFTW_MPI_INCLUDES)
