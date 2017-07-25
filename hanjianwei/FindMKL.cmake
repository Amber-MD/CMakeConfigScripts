# - Find Intel MKL
# modified for AMBER
# Find the MKL libraries
#
# NOTE: if you are using MKL_MULTI_THREADED, this module assumes that you have already called FindOpenMP
# 
# Options:
#
#   MKL_STATIC        :   use static linking.  Requires linker support for the -Wl,--start-group flag.
#   MKL_MULTI_THREADED:   use multi-threading
#	MKL_USE_GNU_COMPAT:   Use the GNU ABI compatibility layer.  Required when using GCC.
#   MKL_SDL           :   Single Dynamic Library interface
#   MKL_MIC           :   Use the Many Integrated Core libraries if they are available
#
# This module defines the following variables:
#
#   MKL_FOUND            : True if MKL_INCLUDE_DIR are found
#   MKL_INCLUDE_DIR      : where to find mkl.h, etc.
#   MKL_INCLUDE_DIRS     : alias for MKL_INCLUDE_DIR
#   MKL_LIBRARIES        : the libraries to link against for your configuration when using C or C++.
#	MKL_FORTRAN_LIBRARIES: the libraries to link against when any Fortran code is being linked
#

include(FindPackageHandleStandardArgs)



if(NOT DEFINED MKL_HOME)
	set(MKL_HOME $ENV{MKL_HOME} CACHE PATH "Root folder of Math Kernel Library")
endif()

# Find include dir
find_path(MKL_INCLUDE_DIR mkl.h PATHS ${MKL_HOME}/include)
set(MKL_INCLUDE_DIRS ${MKL_INCLUDE_DIR})

# Find include directory
#  There is no include folder under linux
if(WIN32)
    find_path(INTEL_INCLUDE_DIR omp.h PATHS ${MKL_HOME}/../include)
    set(MKL_INCLUDE_DIR ${MKL_INCLUDE_DIR} ${INTEL_INCLUDE_DIR})
endif()

# Find libraries

# Handle suffix
set(_MKL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})

if(MKL_STATIC)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
else()
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_IMPORT_LIBRARY_SUFFIX})
endif()

# names of subdirectories in the lib folder
set(MKL_ARCHITECTURES ia32 intel64 em64t)

set(MKL_LIB_PATHS "")
set(MKL_OMP_LIB_PATHS "")# paths to look for the Intel OpenMP runtime library in

foreach(ARCH ${MKL_ARCHITECTURES})
	list(APPEND MKL_LIB_PATHS ${MKL_HOME}/lib/${ARCH})
	list(APPEND MKL_OMP_LIB_PATHS ${MKL_HOME}/../compiler/lib/${ARCH} ${MKL_HOME}/../lib/${ARCH})
endforeach()

# MKL is composed by four layers: Interface, Threading, Computational and OpenMP

if(MKL_SDL)
    find_library(MKL_LIBRARY mkl_rt PATHS ${MKL_LIB_PATHS})

    set(MKL_NEEDED_LIBNAMES MKL_LIBRARY)
    set(MKL_LIBRARIES ${MKL_LIBRARY})
    set(MKL_FORTRAN_LIBRARIES ${MKL_LIBRARY})

    set(CMAKE_FIND_LIBRARY_SUFFIXES ${_MKL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
    
else()
    ######################### Interface layer #######################
    
    # NOTE: right now it's hardcoded to use the 32-bit compatibility versions of certain libraries (lp64 instead of ilp64)
    
    if(WIN32)
        set(MKL_INTERFACE_LIBNAMES mkl_intel_c mkl_intel_c_lp64)
    else()
        set(MKL_INTERFACE_LIBNAMES mkl_intel mkl_intel_lp64)
    endif()

    find_library(MKL_INTERFACE_LIBRARY NAMES ${MKL_INTERFACE_LIBNAMES} PATHS ${MKL_LIB_PATHS})
    
    find_library(MKL_GFORTRAN_INTERFACE_LIBRARY NAMES mkl_gf mkl_gf_lp64 PATHS ${MKL_LIB_PATHS})
    	
    # gfortran specifically needs a seperate library
    if(MKL_USE_GNU_COMPAT)
    	set(MKL_FORTRAN_INTERFACE_LIBRARY MKL_GFORTRAN_INTERFACE_LIBRARY)
	else()
    	set(MKL_FORTRAN_INTERFACE_LIBRARY MKL_INTERFACE_LIBRARY)
	endif()
	
    ######################## Threading layer ########################
    find_library(MKL_SEQUENTIAL_THREADING_LIBRARY mkl_sequential PATHS ${MKL_LIB_PATHS})
    find_library(MKL_INTEL_THREADING_LIBRARY mkl_intel_thread PATHS ${MKL_LIB_PATHS})
    find_library(MKL_GNU_THREADING_LIBRARY mkl_gnu_thread PATHS ${MKL_LIB_PATHS})
    
    if(MKL_MULTI_THREADED)
    	if(MKL_USE_GNU_COMPAT)
    		set(MKL_THREADING_LIBRARY MKL_GNU_THREADING_LIBRARY)	
        else()
        	set(MKL_THREADING_LIBRARY MKL_INTEL_THREADING_LIBRARY)
        endif()
    else()
        set(MKL_THREADING_LIBRARY MKL_SEQUENTIAL_THREADING_LIBRARY)
    endif()
    

    ####################### Computational layer #####################
    find_library(MKL_CORE_LIBRARY mkl_core PATHS ${MKL_LIB_PATHS})
    find_library(MKL_FFT_LIBRARY mkl_cdft_core PATHS ${MKL_LIB_PATHS})
    find_library(MKL_SCALAPACK_LIBRARY mkl_scalapack_core mkl_scalapack_lp64 PATHS ${MKL_LIB_PATHS})

    ############################ OpenMP Library ##########################
    if(WIN32)
        set(MKL_INTEL_OMP_LIBNAME iomp5md)
    else()
        set(MKL_INTEL_OMP_LIBNAME iomp5)
    endif()
    
    # Almost all of the MKL libraries are in MKL_HOME
	# ..but libiomp5.so is NOT!
	#it's in the lib folder of the __DIRECTORY CONTAINING__ MKL_HOME.
    
    find_library(MKL_INTEL_OMP_LIBRARY ${MKL_INTEL_OMP_LIBNAME} PATHS ${MKL_OMP_LIB_PATHS})
    
    if(NOT MKL_MULTI_THREADED)
    	set(MKL_OMP_LIBRARY "") # None needed
    elseif(MKL_USE_GNU_COMPAT)    	    	
    	# we need to pass the OpenMP flag as part of the MKL libraries so that gcc will link libgomp
	    if(NOT DEFINED OpenMP_C_FLAGS)
	    	message(SEND_ERROR "You must call find_package(OpenMP) before finding MKL if you want to use MKL_MULTI_THREADED with MKL_USE_GNU_COMPAT")
		endif()
		set(MKL_OMP_LIBRARY OpenMP_C_FLAGS) # this is wierd, I know, but MKL is just this complicated
    else() # Intel OpenMP
    	set(MKL_OMP_LIBRARY MKL_INTEL_OMP_LIBRARY)    	
    endif()
    
   ############################ Link Options ##########################
    
    
    if(MKL_STATIC)
    	# figure out how to link the static libraries
    	check_linker_flag(-Wl,--start-group C SUPPORTS_LIB_GROUPS)
    	
    	if(NOT SUPPORTS_LIB_GROUPS)
    		message(FATAL_ERROR "Your linker does not support library grouping.  MKL cannot be linked statically on this platform.")
		endif()
		
		set(LIB_LIST_PREFIX -Wl,--start-group)
		set(LIB_LIST_SUFFIX -Wl,--end-group)
		
		if(OPENMP)
			# when we are using static libraries, we need to tell the compiler to link in the OpenMP library explicitly
			list(APPEND LIB_LIST_SUFFIX ${OpenMP_C_FLAGS})
		endif()
	else()
		check_linker_flag(-Wl,--no-as-needed C SUPPORTS_NO_AS_NEEDED)
		
		if(SUPPORTS_NO_AS_NEEDED)
			set(LIB_LIST_PREFIX -Wl,--no-as-needed)
		else()
			# we *hope* that the linker doesn't do as-needed linking at all and thus the flag is not necessary
			set(LIB_LIST_PREFIX "")
		endif()
		set(LIB_LIST_SUFFIX "")
	endif()
    
    # Library names to pass to FPHSA
    set(MKL_NEEDED_LIBNAMES MKL_INTERFACE_LIBRARY ${MKL_FORTRAN_INTERFACE_LIBRARY} ${MKL_THREADING_LIBRARY} MKL_CORE_LIBRARY)
    
    # prevent choking when the OpenMP flag is an empty string
    if(NOT (DEFINED "${MKL_OMP_LIBRARY}" AND "${${MKL_OMP_LIBRARY}}" STREQUAL ""))
    	list(APPEND MKL_NEEDED_LIBNAMES ${MKL_OMP_LIBRARY})
	endif()
    
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${_MKL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
    
    ############################ Extra Libraries ##########################
    
    
    # link libdl if it exists
    find_library(LIBDL dl PATHS "")
    if(LIBDL)
	    check_library_exists(dl dlopen ${LIBDL} HAVE_LIBDL)
    else()
    	set(HAVE_LIBDL FALSE)
    endif()
    
    
    if(HAVE_LIBDL)
    	set(MKL_LIBDL ${LIBDL})
    else()
    	set(MKL_LIBDL "")
    endif()
    
    # Link pthread if it exists
    find_package(Threads)
    
    if(CMAKE_THREAD_LIBS_INIT)
    	set(MKL_PTHREAD_LIB Threads::Threads)
	else()
		set(MKL_PTHREAD_LIB "")
	endif()
    
    # Build the final library lists    
    set(MKL_LIBRARIES ${LIB_LIST_PREFIX} ${${MKL_OMP_LIBRARY}} ${MKL_CORE_LIBRARY} 
    	${${MKL_THREADING_LIBRARY}} ${MKL_INTERFACE_LIBRARY} ${LIB_LIST_SUFFIX} ${MKL_LIBDL} ${MKL_PTHREAD_LIB})
    set(MKL_FORTRAN_LIBRARIES ${LIB_LIST_PREFIX} ${${MKL_OMP_LIBRARY}} ${MKL_CORE_LIBRARY} 
    	${${MKL_THREADING_LIBRARY}} ${${MKL_FORTRAN_INTERFACE_LIBRARY}} ${LIB_LIST_SUFFIX} ${MKL_LIBDL} ${MKL_PTHREAD_LIB})
endif()

find_package_handle_standard_args(MKL DEFAULT_MSG MKL_INCLUDE_DIR ${MKL_NEEDED_LIBNAMES})