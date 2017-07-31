# File which figures out the compiler flags to use based on the vendor and version of each compiler
#Note: must be included after OpenMPConfig and MPIConfig

#-------------------------------------------------------------------------------
#  Handle CMake fortran compiler version issue
#  See https://cmake.org/Bug/view.php?id=15372
#-------------------------------------------------------------------------------
	
if(CMAKE_Fortran_COMPILER_LOADED AND "${CMAKE_Fortran_COMPILER_VERSION}" STREQUAL "")

	set(CMAKE_Fortran_COMPILER_VERSION ${CMAKE_C_COMPILER_VERSION} CACHE STRING "Fortran compiler version.  May not be autodetected correctly on older CMake versions, fix this if it's wrong." FORCE)
	message(FATAL_ERROR "Your CMake is too old to properly detect the Fortran compiler version.  It is assumed to be the same as your C compiler version, ${CMAKE_C_COMPILER_VERSION}. If this is not correct, pass -DCMAKE_Fortran_COMPILER_VERSION=<correct version> to cmake.  If it is correct,just run the configuration again.")
	
endif()
	

# create linker flags
# On Windows undefined symbols in shared libraries produce errors.
# This makes them do that on Linux too.
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${NO_UNDEFINED_FLAG}")

#-------------------------------------------------------------------------------
#  Now, the If Statements of Doom...
#-------------------------------------------------------------------------------

#gcc
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

if("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
	add_flags(C -Wall -Wno-unused-function -Wno-unknown-pragmas)
	
	if(NOT UNUSED_WARNINGS)
		add_flags(C -Wno-unused-variable -Wno-unused-but-set-variable)
	endif()
	
	if(NOT UNINITIALIZED_WARNINGS)
		add_flags(C -Wno-uninitialized -Wno-maybe-uninitialized)
	endif()
	
	if(${CMAKE_C_COMPILER_VERSION} VERSION_GREATER 4.1)
		if(SSE)
			if(TARGET_ARCH STREQUAL x86_64)
          		#-mfpmath=sse is default for x86_64, no need to specific it
          		set(OPT_CFLAGS ${OPT_CFLAGS} "-mtune=native")
        	else() # i386 needs to be told to use sse prior to using -mfpmath=sse
          		set(OPT_CFLAGS "${OPT_CFLAGS} -mtune=native -msse -mfpmath=sse")
         	endif()
         endif()
	endif()    
  
	if(DRAGONEGG)
		#check dragonegg
		check_c_compiler_flag(-fplugin=${DRAGONEGG} DRAGONEGG_C_WORKS)
		if(NOT DRAGONEGG_C_WORKS)
			message(FATAL_ERROR "Can't use C compiler with Dragonegg.  Please fix whatever's broken.  Check CMakeOutput.log for details.")
		endif()
		
		add_flags(C -fplugin=${DRAGONEGG})
	endif()
endif()
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")

	add_flags(CXX -Wall -Wno-unused-function -Wno-unknown-pragmas)

	# Kill it!  Kill it with fire!
	check_cxx_compiler_flag(-Wno-unused-local-typedefs SUPPORTS_WNO_UNUSED_LOCAL_TYPEDEFS)

	if(SUPPORTS_WNO_UNUSED_LOCAL_TYPEDEFS)
		add_flags(CXX -Wno-unused-local-typedefs)
	endif()
	
	if(NOT UNUSED_WARNINGS)
		add_flags(CXX -Wno-unused-variable -Wno-unused-but-set-variable)
	endif()
	
	if(NOT UNINITIALIZED_WARNINGS)
		add_flags(CXX -Wno-uninitialized -Wno-maybe-uninitialized)
	endif()
	
	if(${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 4.1)
		if(SSE)
			if(TARGET_ARCH STREQUAL x86_64)
          		#-mfpmath=sse is default for x86_64, no need to specific it
          		set(OPT_CXXFLAGS ${OPT_CXXFLAGS} "-mtune=native")
        	else() # i386 needs to be told to use sse prior to using -mfpmath=sse
          		set(OPT_CXXFLAGS "${OPT_CXXFLAGS} -mtune=native -msse -mfpmath=sse")
         	endif()
         endif()
	endif()    
  
	if(DRAGONEGG)
		#check dragonegg
		check_cxx_compiler_flag(-fplugin=${DRAGONEGG} DRAGONEGG_CXX_WORKS)
		if(NOT DRAGONEGG_CXX_WORKS)
			message(FATAL_ERROR "Can't use C++ compiler with Dragonegg.  Please fix whatever's broken.  Check CMakeOutput.log for details.")
		endif()
		
		add_flags(CXX -fplugin=${DRAGONEGG})
	endif()
endif()
if("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "GNU")

	add_flags(Fortran -Wall -Wno-tabs -Wno-unused-function -ffree-line-length-none -Wno-unused-dummy-argument)
		
	if(NOT UNUSED_WARNINGS)
		add_flags(Fortran -Wno-unused-variable)
	endif()
		
	if(NOT UNINITIALIZED_WARNINGS)
		add_flags(Fortran -Wno-maybe-uninitialized)
	endif()	
		
	if("${CMAKE_Fortran_COMPILER_VERSION}" VERSION_GREATER 4.1)
		if(SSE)
			if(TARGET_ARCH STREQUAL x86_64)
          		#-mfpmath=sse is default for x86_64, no need to specific it
          		set(OPT_FFLAGS ${OPT_FFLAGS} -mtune=native)
        	else() # i386 needs to be told to use sse prior to using -mfpmath=sse
          		set(OPT_FFLAGS ${OPT_FFLAGS} -mtune=native -msse -mfpmath=sse)
         	endif()
         endif()
	endif()
	
	
	# gcc 4.1.2 does not support putting allocatable arrays in a Fortran type...
    # so unfortunately file-less prmtop support in the sander API will not work
    # in this case.
    if("${CMAKE_Fortran_COMPILER_VERSION}" VERSION_LESS 4.2)
        add_definitions(-DNO_ALLOCATABLES_IN_TYPE)
    endif()
    
    # Check dragonegg
	if(DRAGONEGG)
		#TODO: write check_fortran_compiler_flag
		#check_fortran_compiler_flag(-fplugin=${DRAGONEGG} DRAGONEGG_FORTRAN_WORKS)
		#if(NOT DRAGONEGG_FORTRAN_WORKS)
		#	message(FATAL_ERROR "Can't use Fortran compiler with Dragonegg.  Please fix whatever's broken.  Check CMakeOutput.log for details.")
		#endif()
		
		add_flags(Fortran -fplugin=${DRAGONEGG})
	endif()
endif()

#clang
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

if("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
	add_flags(C -Wall -Wno-unused-function)
	
	list(APPEND OPT_CFLAGS "-mtune=native")
	
	#if we are crosscompiling and using clang, tell CMake this
	if(CROSSCOMPILE)
		set(CMAKE_C_COMPILER_TARGET ${TARGET_TRIPLE})
	endif()  
	
	if(NOT UNINITIALIZED_WARNINGS)
		add_flags(C -Wno-sometimes-uninitialized)
	endif()
	
	if(OPENMP AND (${CMAKE_C_COMPILER_VERSION} VERSION_LESS 3.7))
		message(FATAL_ERROR "Clang versions earlier than 3.7 do not support OpenMP!  Disable it or change compilers!")
	endif()
		
endif()
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
	add_flags(CXX -Wall -Wno-unused-function)
	
	list(APPEND OPT_CXXFLAGS "-mtune=native")
	
	if(CROSSCOMPILE)
		set(CMAKE_CXX_COMPILER_TARGET ${TARGET_TRIPLE})
	endif()
	
	if(NOT UNINITIALIZED_WARNINGS)
		add_flags(C -Wno-sometimes-uninitialized)
	endif()
	
	if(OPENMP AND (${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS 3.7))
		message(FATAL_ERROR "Clang versions earlier than 3.7 do not support OpenMP!  Disable it or change compilers!")
	endif()
endif()

#msvc
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

if("${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC")
	add_flags(C /D_CRT_SECURE_NO_WARNINGS)
	
	set(OPT_CFLAGS "/Ox")
	
	set(CMAKE_C_FLAGS_DEBUG "/Zi")
endif()
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
	add_flags(CXX /D_CRT_SECURE_NO_WARNINGS)
	
	set(OPT_CXXFLAGS "/Ox")
	
	set(CMAKE_CXX_FLAGS_DEBUG "/Zi")
endif()

#intel
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

if("${CMAKE_C_COMPILER_ID}" STREQUAL "Intel")
	set(CMAKE_C_FLAGS_DEBUG "-g -debug all")
	
	set(OPT_CFLAGS -ip -O3)
		
	#  How flags get set for optimization depend on whether we have a MIC processor,
    #  the version of Intel compiler we have, and whether we are cross-compiling
    #  for multiple versions of SSE support.  The following coordinates all of this.
    #  This was done assuming that MIC and SSE are mutually exclusive and that we want
    #  SSE instructions included only when optimize = yes.  Note that use of an
    #  SSE_TYPES specification needs to be given in place of xHost not in addition to.
    #  This observed behavior is not what is reported by the Intel man pages. BPK
	
	if(SSE)
		# BPK removed section that modified O1 or O2 to be O3 if optimize was set to yes.
      	# We already begin with the O3 setting so it wasn't needed.
        # For both coptflags and foptflags, use the appropriate settings
        # for the sse flags (compiler version dependent).
        if(${CMAKE_C_COMPILER_VERSION} VERSION_GREATER 11 OR ${CMAKE_C_COMPILER_VERSION} VERSION_EQUAL 11)
			if(NOT "${SSE_TYPES}" STREQUAL "")
				list(APPEND OPT_CFLAGS "-ax${SSE_TYPES}")
			elseif(NOT MPI)
				list(APPEND OPT_CFLAGS -xHost)
			endif()
		else()
			list(APPEND OPT_CFLAGS -axSTPW)
		endif()
		
	endif()
endif()

if("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "Intel")

	if(WIN32)
		add_flags(Fortran /D_CRT_SECURE_NO_WARNINGS)
	
		set(OPT_FFLAGS "/Ox")
		
		set(CMAKE_Fortran_FLAGS_DEBUG "/Zi")
	else()
		set(CMAKE_Fortran_FLAGS_DEBUG "-g -debug all")
		
		set(OPT_FFLAGS -ip -O3)
			
		if(SSE)

			if("${CMAKE_Fortran_COMPILER_VERSION}" VERSION_GREATER 11 OR ${CMAKE_Fortran_COMPILER_VERSION} VERSION_EQUAL 11)
				if(NOT "${SSE_TYPES}" STREQUAL "")
					list(APPEND OPT_FFLAGS "-ax${SSE_TYPES}")
				elseif(NOT MPI)
					list(APPEND OPT_FFLAGS -xHost)
				endif()
			else()
				list(APPEND OPT_FFLAGS -axSTPW)
			endif()
		endif()
		
		
		# warning flags
		add_flags(Fortran "-warn all" "-warn nounused")
		
	endif()
endif()

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
	set(CMAKE_CXX_FLAGS_DEBUG "-g -debug all")
	
	set(OPT_CXXFLAGS -O3)
endif()

# PGI
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
if("${CMAKE_C_COMPILER_ID}" STREQUAL "PGI")
	set(OPT_CFLAGS -O2)
endif()

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "PGI")
	set(OPT_CXXFLAGS -O2)
endif()

if("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "PGI")
	set(OPT_FFLAGS -fast -O3)
	set(NO_OPT_FFLAGS -O1)
	
	if(SSE)
		list(APPEND OPT_FFLAGS -fastsse)
	endif()
	
endif()

# Cray
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
if("${CMAKE_C_COMPILER_ID}" STREQUAL "Cray")
endif()

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Cray")
endif()

if("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "Cray")
endif()

#-------------------------------------------------------------------------------
#  Add some non-compiler-dependent items
#-------------------------------------------------------------------------------
if(LARGE_FILE_SUPPORT)
	add_definitions(-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE)
endif()

check_symbol_exists(mkstemp stdlib.h HAVE_MKSTEMP)
if(HAVE_MKSTEMP)
    add_definitions(-DUSE_MKSTEMP)
endif()

#this doesn't seem to get defined automatically, at least in some situations
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	add_definitions(-DWIN32)
endif()

if(NOT DOUBLE_PRECISION)
	add_definitions(-D_REAL_) #This is read by dprec.fh, where it determines the type of precision to use
endif()

# This definition gets applied to everything, everywhere
# I think you used to be able to enable or disable netcdf, and this was the switch for it
add_definitions(-DBINTRAJ)

#-------------------------------------------------------------------------------
#  finalize the flags
#-------------------------------------------------------------------------------

#put the opt cxxflags into the CUDA flags
foreach(FLAG ${OPT_CXXFLAGS})
	list(APPEND HOST_NVCC_FLAGS ${FLAG})
endforeach()


# disable optimization flags if optimization is disabled
if(NOT OPTIMIZE)
	set(OPT_FFLAGS ${NO_OPT_FFLAGS})
	set(OPT_CFLAGS ${NO_OPT_CFLAGS})
	set(OPT_CXXFLAGS ${NO_OPT_CXXFLAGS})
endif()

#create space-separated versions of each flag set for use in PROPERTY COMPILE_FLAGS
list_to_space_seperated(OPT_FFLAGS_SPC ${OPT_FFLAGS})
list_to_space_seperated(OPT_CFLAGS_SPC ${OPT_CFLAGS})
list_to_space_seperated(OPT_CXXFLAGS_SPC ${OPT_CXXFLAGS})

list_to_space_seperated(NO_OPT_FFLAGS_SPC ${NO_OPT_FFLAGS})
list_to_space_seperated(NO_OPT_CFLAGS_SPC ${NO_OPT_CFLAGS})
list_to_space_seperated(NO_OPT_CXXFLAGS_SPC ${NO_OPT_CXXFLAGS})


# When a library links to an imported library with interface include directories, CMake uses the -isystem flag to include  those directories
# Unfortunately, this seems to completely not work with Fortran, so we disable it.
set(CMAKE_NO_SYSTEM_FROM_IMPORTED TRUE) 
