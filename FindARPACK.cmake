# - Find ARPACK
# Finds the arpack library on your system, and check that it is able to be linked to with the current compiler.
# This module defines:
#
#  ARPACK_LIBRARY      -- the library needed to use Arpack
#  ARPACK_FOUND        -- if false, do not try to use PUPIL.
#  ARPACK_HAS_ARSECOND -- true if the discovered Arpack library contains the arsecond_ function.  Only defined if Arpack was found.

include(FindPackageHandleStandardArgs)

find_library(ARPACK_LIBRARY arpack)

set(FIND_ARPACK_FAILURE_MESSAGE "The ARPACK library was not found.  Please set ARPACK_LIBRARY to point to it.")

if(EXISTS "${ARPACK_LIBRARY}")

	# NOTE: if/when Amber is updated for other Fortran manglings, this section should be updated to use FortranCInterface

	set(CMAKE_REQUIRED_LIBRARIES ${ARPACK_LIBRARY})
	
	# check that Arpack is linkable.
	# if, say, the compiler was using a different fortran runtime than Arpack was compiled with, then the library would be found
	# but this would fail.
	check_function_exists(dsaupd_ ARPACK_IS_LINKABLE)
	
	if(ARPACK_IS_LINKABLE)
	
		# Test for arsecond_
		set(CMAKE_REQUIRED_LIBRARIES ${ARPACK_LIBRARY})
		#Some arpacks (e.g. Ubuntu's package manager's one) don't have the arsecond_ function from wallclock.c
		#sff uses it, so we have to tell sff to build it
		check_function_exists(arsecond_ ARPACK_HAS_ARSECOND)
		
	else()
		set(FIND_ARPACK_FAILURE_MESSAGE "The ARPACK library was found, but ${ARPACK_LIBRARY} is not linkable.  Perhaps it was built with an incompatible Fortran compiler? \
Please set ARPACK_LIBRARY to point to a working ARPACK library.")
	endif()
	
	set(CMAKE_REQUIRED_LIBRARIES "")

else()

	# make sure that this variable isn't hanging around from a previous time when Arpack was found
	unset(ARPACK_HAS_ARSECOND CACHE)
endif()

find_package_handle_standard_args(ARPACK ${FIND_ARPACK_FAILURE_MESSAGE} ARPACK_LIBRARY ARPACK_IS_LINKABLE)