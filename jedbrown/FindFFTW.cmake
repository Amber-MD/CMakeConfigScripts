# - Find FFTW
# Find the native FFTW includes and library
#
#  FFTW_INCLUDES    - where to find fftw3.h
#  FFTW_LIBRARIES[_SHARED,_STATIC]   - List of libraries when using FFTW.
#  FFTW_FOUND       - True if FFTW found.
#  FFTW_IS_SHARED   - True if FFTW_LIBRARIES points to a shared library
#  FFTW_LIB_TYPE    - "SHARED" if FFTW_IS_SHARED is TRUE, "STATIC" otherwise

if (FFTW_INCLUDES)
  # Already in cache, be silent
  set (FFTW_FIND_QUIETLY TRUE)
endif (FFTW_INCLUDES)

find_path (FFTW_INCLUDES fftw3.h)

find_library (FFTW_LIBRARIES NAMES fftw3)
find_library (FFTW_LIBRARIES_STATIC   NAMES libfftw3.a)
find_library (FFTW_LIBRARIES_SHARED   NAMES fftw3${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_SHARED_LIBRARY_PREFIX}fftw3${CMAKE_SHARED_LIBRARY_SUFFIX})
mark_as_advanced(FFTW_LIBRARIES_STATIC FFTW_LIBRARIES_SHARED)

#prefer shared libraries, but fall back to static
if(FFTW_LIBRARIES_SHARED)
	set(FFTW_LIBRARIES ${FFTW_LIBRARIES_SHARED})
	set(FFTW_IS_SHARED TRUE)
	set(FFTW_LIB_TYPE SHARED)
else()
	set(FFTW_LIBRARIES ${FFTW_LIBRARIES_STATIC})
	set(FFTW_IS_SHARED FALSE)
	set(FFTW_LIB_TYPE STATIC)
endif()


# handle the QUIETLY and REQUIRED arguments and set FFTW_FOUND to TRUE if
# all listed variables are TRUE
include (FindPackageHandleStandardArgs)
find_package_handle_standard_args (FFTW DEFAULT_MSG FFTW_LIBRARIES FFTW_INCLUDES)

mark_as_advanced (FFTW_LIBRARIES FFTW_INCLUDES)
