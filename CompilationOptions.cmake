# This file can be included after at least one language is enabled, but before all of them are.
# It sets up all of the CMake options that affect compiler flags.

# Set up options which affect compiler flags.
#------------------------------------------------------------------------------------------

#Dragonegg option
set(DRAGONEGG "" CACHE PATH "Path to the the Dragonegg gcc to LLVM bridge. Set to empty string to disable.  If specified, it will be applied to any GCC compilers in use (gcc, g++, and gfortran).")

 # Check dragonegg
if(DRAGONEGG)
	if(NOT EXISTS ${DRAGONEGG})
		message(FATAL_ERROR "Dragonegg enabled, but the Dragonegg path ${DRAGONEGG} does not point to a file.")    
    endif()
endif()

#shared vs static option
option(STATIC "If true, build static libraries and freestanding (except for data files) executables. Otherwise, compile common code into shared libraries and link them to programs.
	The runtime path is set properly now, so unless you move the installation AND don't source amber.sh you won't have to mess with LD_LIBRARY PATH" FALSE)

if(STATIC)
	set(SHARED FALSE)
else()
	set(SHARED TRUE)
endif()		

option(LARGE_FILE_SUPPORT "Build C code with large file support" TRUE)

#set default library type appropriately
set(BUILD_SHARED_LIBS ${SHARED})

# NOTE: The correct way to handle optimization is to use generator expressions based on the current configuration.
# However, sometimes I need to use set_property(SOURCE PROPERTY COMPILE_FLAGS) to set compile flags for individual source files.
# This property didn't support generator expressions until CMake 3.8. Grrrrr.
# So, we use CMAKE_<LANG>_FLAGS_DEBUG for per-config debugging flags, but use a separate optimization switch.
option(OPTIMIZE "Whether to build code with compiler flags for optimization." TRUE)

option(UNUSED_WARNINGS "Enable warnings about unused variables.  Really clutters up the build output." TRUE)
option(UNINITIALIZED_WARNINGS "Enable warnings about uninitialized variables.  Kind of clutters up the build output, but these need to be fixed." TRUE)

#-------------------------------------------------------------------------------
#  Set default flags
#-------------------------------------------------------------------------------

#let's try to enforce a reasonable standard here
set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 11)

set(NO_OPT_FFLAGS -O0)
set(NO_OPT_CFLAGS -O0)
set(NO_OPT_CXXFLAGS -O0)

set(OPT_FFLAGS -O3)
set(OPT_CFLAGS -O3)
set(OPT_CXXFLAGS -O3)

set(CMAKE_C_FLAGS_DEBUG "-g")
set(CMAKE_CXX_FLAGS_DEBUG "-g")
set(CMAKE_Fortran_FLAGS_DEBUG "-g")

#blank cmake's default optimization flags, we can't use these because not everything should be built optimized.
set(CMAKE_C_FLAGS_RELEASE "")
set(CMAKE_CXX_FLAGS_RELEASE "")
set(CMAKE_Fortran_FLAGS_RELEASE "")

#a macro to make things a little cleaner
#NOTE: we can't use add_compile_options because that will apply to all languages
macro(add_flags LANGUAGE) # FLAGS...
	foreach(FLAG ${ARGN})
		set(CMAKE_${LANGUAGE}_FLAGS "${CMAKE_${LANGUAGE}_FLAGS} ${FLAG}")
	endforeach()
endmacro(add_flags)

#------------------------------------------------------------------------------
#  Now that we have our compiler, detect target architecture.
#  This is kind of a hack, but it works.
#  See TargetArch.cmake (from https://github.com/axr/solar-cmake) for details.  
#------------------------------------------------------------------------------
target_architecture(TARGET_ARCH)

if(${TARGET_ARCH} STREQUAL unknown)
	message(FATAL_ERROR "Could not detect target architecture from compiler.  Does the compiler work?")
endif()   


#initialize SSE based on TARGET_ARCH
list_contains(SSE_SUPPORTED ${TARGET_ARCH} x86_64 ia64 i386)
set(SSE ${SSE_SUPPORTED} CACHE BOOL "Optimize for the SSE family of vectorizations.")
set(SSE_TYPES "" CACHE STRING "CPU types for which auto-dispatch code will be produced (Intel compilers version 11 and higher). Known valid
	options are SSE2, SSE3, SSSE3, SSE4.1 and SSE4.2. Multiple options (comma separated) are permitted.")

# Figure out no-undefined flag
if(${CMAKE_SYSTEM_NAME} STREQUAL Darwin)
	set(NO_UNDEFINED_FLAG "-Wl,-undefined,error")
elseif((${CMAKE_SYSTEM_NAME} STREQUAL Linux) OR MINGW)
	set(NO_UNDEFINED_FLAG "-Wl,--no-undefined")
else()
	set(NO_UNDEFINED_FLAG "")
endif()


#-------------------------------------------------------------------------------
# Set up a couple of convenience variables to make checking the target OS less verbose
#-------------------------------------------------------------------------------
test(TARGET_OSX "${CMAKE_SYSTEM_NAME}" STREQUAL Darwin)
test(TARGET_WINDOWS "${CMAKE_SYSTEM_NAME}" STREQUAL Windows)
test(TARGET_LINUX "${CMAKE_SYSTEM_NAME}" STREQUAL Linux)
