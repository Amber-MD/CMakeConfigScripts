# - Find FFTW
# Find the native FFTW includes and library
# Components:
#	MPI Fortran
#  FFTW_INCLUDES    - where to find fftw3.h
#  FFTW_LIBRARIES	- List of libraries when using FFTW.
#  FFTW_FOUND       - True if FFTW found.
# when using components:
#   FFTW_INCLUDES_SERIAL   - include path for FFTW serial
#	FFTW_LIBRARIES_SERIAL  - library for use of fftw from C and Fortran
#	FFTW_INCLUDES_MPI      - include path for FFTW MPI
#	FFTW_LIBRARIES_MPI 	   - extra FFTW library to use MPI
# Why is there a "Fortran" component you ask?  It's because some systems lack the Fortran headers (fftw3.f03)

if (FFTW_FOUND)
  # Already in cache, be silent
  set (FFTW_FIND_QUIETLY TRUE)
endif()

# headers
# --------------------------------------------------------------------

find_path (FFTW_INCLUDES_SERIAL fftw3.h)

set(FFTW_INCLUDES ${FFTW_INCLUDES_SERIAL})

# libraries
# --------------------------------------------------------------------
find_library(FFTW_LIBRARIES_SERIAL NAMES fftw3 NO_SYSTEM_ENVIRONMENT_PATH)
set(FFTW_LIBRARIES ${FFTW_LIBRARIES_SERIAL})

# Fortran component
# --------------------------------------------------------------------

if("${FFTW_FIND_COMPONENTS}" MATCHES "Fortran")

	# should exist if Fortran support is present
	set(FFTW_FORTRAN_HEADER "${FFTW_INCLUDES}/fftw3.f03")
	
	if(EXISTS "${FFTW_FORTRAN_HEADER}")
		set(FFTW_Fortran_FOUND TRUE)
	else()
		set(FFTW_Fortran_FOUND FALSE)
		message(STATUS "Cannot find FFTW Fortran headers - ${FFTW_FORTRAN_HEADER} should have been present, but wasn't")
	endif()
endif()

# MPI component
# --------------------------------------------------------------------
if("${FFTW_FIND_COMPONENTS}" MATCHES "MPI")
	find_library(FFTW_LIBRARIES_MPI NAMES fftw3_mpi NO_SYSTEM_ENVIRONMENT_PATH)
	list(APPEND FFTW_LIBRARIES ${FFTW_LIBRARIES_MPI})
	
	find_path(FFTW_INCLUDES_MPI fftw3-mpi.h)
	list(APPEND FFTW_INCLUDES ${FFTW_INCLUDES_MPI})
	
	if((EXISTS "${FFTW_LIBRARIES_MPI}") AND (EXISTS "${FFTW_INCLUDES_MPI}"))
		set(FFTW_MPI_FOUND TRUE)
	else()
		set(FFTW_MPI_FOUND FALSE)
		
		if(NOT EXISTS "${FFTW_LIBRARIES_MPI}")
			message(STATUS "Cannot find MPI FFTW - the libfftw3_mpi library could not be located.  Please define the CMake variable FFTW_LIBRARIES_MPI to point to it.")
		else()
			message(STATUS "Cannot find MPI FFTW - fftw3-mpi.h could not be located.  Please define the CMake variable FFTW_INCLUDES_MPI to point to the directory containing it.")
		endif()
	endif()
	
	if("${FFTW_FIND_COMPONENTS}" MATCHES "Fortran" AND FFTW_Fortran_FOUND)
	
		set(FFTW_FORTRAN_MPI_HEADER "${FFTW_INCLUDES_MPI}/fftw3-mpi.f03")
		
		# reevaluate our life choices
		if(EXISTS "${FFTW_FORTRAN_HEADER}")
			set(FFTW_Fortran_FOUND TRUE)
		else()
			set(FFTW_Fortran_FOUND FALSE)
			message(STATUS "Cannot find FFTW Fortran headers - ${FFTW_FORTRAN_MPI_HEADER} should have been present, but wasn't")
		endif()
	endif()
	
	mark_as_advanced (FFTW_LIBRARIES_MPI FFTW_INCLUDES_MPI)
	
endif()

# handle the QUIETLY and REQUIRED arguments and set FFTW_FOUND to TRUE if
# all listed variables are TRUE
include (FindPackageHandleStandardArgs)
find_package_handle_standard_args (FFTW HANDLE_COMPONENTS REQUIRED_VARS FFTW_LIBRARIES_SERIAL FFTW_INCLUDES_SERIAL)

mark_as_advanced (FFTW_INCLUDES_SERIAL FFTW_INCLUDES_SERIAL)
