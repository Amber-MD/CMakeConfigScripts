# Amber: taken from https://fossies.org/linux/orocos-ocl/ocl/config/FindLog4cxx.cmake

################################################################################
#
# CMake script for finding Log4cxx.
# The default CMake search process is used to locate files.
#
# This script creates the following variables:
#  LOG4CXX_FOUND: Boolean that indicates if the package was found
#  LOG4CXX_INCLUDE_DIR: Path to the necessary header files
#  LOG4CXX_LIBRARY: Package library
#
################################################################################

include(FindPackageHandleStandardArgs)
include(LibFindMacros)

# See if LOG4CXX_ROOT is not already set in CMake
IF (NOT LOG4CXX_ROOT)
    # See if LOG4CXX_ROOT is set in process environment
    IF ( NOT $ENV{LOG4CXX_ROOT} STREQUAL "" )
        SET (LOG4CXX_ROOT "$ENV{LOG4CXX_ROOT}")
	MESSAGE(STATUS "Detected LOG4CXX_ROOT set to '${LOG4CXX_ROOT}'")
    ENDIF ()
ENDIF ()

# If LOG4CXX_ROOT is available, set up our hints
IF (LOG4CXX_ROOT)
    SET (LOG4CXX_INCLUDE_HINTS "${LOG4CXX_ROOT}/include" "${LOG4CXX_ROOT}")
    SET (LOG4CXX_LIBRARY_HINTS "${LOG4CXX_ROOT}/lib")
else()
	# Use pkg-config to get hints about paths
	libfind_pkg_check_modules(LOG4CXX_PKGCONF log4cxx)
	set(LOG4CXX_INCLUDE_HINTS ${LOG4CXX_PKGCONF_INCLUDE_DIRS})
    set(LOG4CXX_LIBRARY_HINTS ${LOG4CXX_PKGCONF_LIBRARY_DIRS})
endif()

# Find headers and libraries
find_path(LOG4CXX_INCLUDE_DIR NAMES log4cxx/log4cxx.h HINTS ${LOG4CXX_INCLUDE_HINTS})
find_library(LOG4CXX_LIBRARY NAMES log4cxx HINTS ${LOG4CXX_LIBRARY_HINTS})
find_library(LOG4CXXD_LIBRARY NAMES log4cxx${CMAKE_DEBUG_POSTFIX} HINTS ${LOG4CXX_LIBRARY_HINTS})

# Set LOG4CXX_FOUND honoring the QUIET and REQUIRED arguments
find_package_handle_standard_args(LOG4CXX DEFAULT_MSG LOG4CXX_LIBRARY LOG4CXX_INCLUDE_DIR)

# Advanced options for not cluttering the cmake UIs
mark_as_advanced(LOG4CXX_INCLUDE_DIR LOG4CXX_LIBRARY)