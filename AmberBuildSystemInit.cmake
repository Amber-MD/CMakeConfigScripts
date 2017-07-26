# This file contains code which must run to start up the build system, and includes files that are common to Amber and every submodule.
# This file must run AFTER a project() command without any languages, but BEFORE the enable_language() command

if(NOT DEFINED FIRST_RUN)

	# create a cache variable which is shadowed by a local variable
	set(FIRST_RUN FALSE CACHE INTERNAL "Variable to track if it is currently the first time the build system is run" FORCE)
	set(FIRST_RUN TRUE)

endif()

# configure module path
# --------------------------------------------------------------------

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR} 
	"${CMAKE_CURRENT_LIST_DIR}/jedbrown" 
	"${CMAKE_CURRENT_LIST_DIR}/hanjianwei" 
	"${CMAKE_CURRENT_LIST_DIR}/rpavlik" 
	"${CMAKE_CURRENT_LIST_DIR}/patched-cmake-modules")
	
# includes
# --------------------------------------------------------------------

#Basic utilities.  These files CANNOT use any sort of compile checks, because AmberCompilerConfig needs to set that up.
include(CMakeParseArguments)
include(Utils)
include(Shorthand)
include(ColorMessage)
include(Policies)

#run manual compiler setter, if it is enabled
include(AmberCompilerConfig)

# install subdirectory setup
# --------------------------------------------------------------------

set(BINDIR "bin") #binary subdirectory in install location
set(LIBDIR "lib") #shared library subdirectory in install location
set(DATADIR "dat") #subdirectory for programs' data files
set(DOCDIR "doc")
set(INCDIR "include")

#directory for runtime (shared) libraries
if(WIN32)
	set(DLLDIR ${BINDIR}) #put on PATH
else()
	set(DLLDIR ${LIBDIR})
	
	#set runtime library search path
	set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${LIBDIR}")
	set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
endif()

#control default build type.
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

set(CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "Allowed build types for Amber.  This only controls debugging flags, set the OPTIMIZE variable to control compiler optimizations." FORCE)
if("${CMAKE_BUILD_TYPE}" STREQUAL "")
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Type of build.  Controls debugging information and optimizations." FORCE)
endif()
