#  This file configures which 3rd party tools are built in and which are used from the system.
#  NOTE: must be included after WhichTools.cmake

message(STATUS "Checking whether to use built-in libraries...")


#List of 3rd party tools.
set(3RDPARTY_TOOLS
blas
lapack
arpack 
byacc
ucpp
c9x-complex
netcdf
netcdf-fortran
pnetcdf
fftw
readline  
xblas
lio
apbs
pupil
zlib
libbz2
plumed
libm
qt4
log4cxx
mkl
mpi4py
perlmol)

set(3RDPARTY_TOOL_USES
"for fundamental linear algebra calculations"                                     
"for fundamental linear algebra calculations"                                     
"for fundamental linear algebra calculations"                                     
"for compiling Amber's yacc parsers"                                              
"used as a preprocessor for the NAB compiler"                                     
"used as a support library on systems that do not have C99 complex.h support"     
"for creating trajectory data files"                                              
"for creating trajectory data files from Fortran"                                 
"used by cpptraj for parallel trajectory output"                                  
"used to do Fourier transforms very quickly"                                      
"used for the console functionality of gleap and cpptraj"                         
"used for high-precision linear algebra calculations"                             
"used by Sander to run certain QM routines on the GPU"                            
"used by Sander as an alternate Poisson-Boltzmann equation solver"                
"used by Sander as an alternate user interface"                                   
"for various compression and decompression tasks"                                 
"for bzip2 compression in cpptraj"                                                
"used as an alternate MD backend for Sander"                                      
"for fundamental math routines if they are not contained in the C library"        
"for XML handling in MTK++"                                                       
"for logging in MTK++"                                                            
"alternate implementation of lapack and blas that is tuned for speed"             
"MPI support library for MMPBSA.py"                                               
"chemistry library used by FEW")                                                  

# Logic to disable tools
set(3RDPARTY_SUBDIRS "")

#sets a tool to external, internal, or disabled
#STATUS=EXTERNAL, INTERNAL, or DISABLED
macro(set_3rdparty TOOL STATUS)
	set(${TOOL}_INTERNAL FALSE)
	set(${TOOL}_EXTERNAL FALSE)
	set(${TOOL}_DISABLED FALSE)
	set(${TOOL}_ENABLED TRUE)
	
	
	if(${STATUS} STREQUAL EXTERNAL)
		set(${TOOL}_EXTERNAL TRUE)
	elseif(${STATUS} STREQUAL INTERNAL)
		
		#the only way to get this message would be to use FORCE_INTERNAL_LIBS incorrectly, unless someone messed up somewhere
		if("${BUNDLED_3RDPARTY_TOOLS}" MATCHES ${TOOL})
				set(${TOOL}_INTERNAL TRUE)
		else()
			if(INSIDE_AMBER)
				# getting here means there's been a programming error
				message(FATAL_ERROR "3rd party program ${TOOL} is not bundled and cannot be built inside Amber.")
			elseif("${REQUIRED_3RDPARTY_TOOLS}" MATCHES ${TOOL})
				# kind of a kludge - even when we're in a submodule, things will still get set top internal, so we just treat internal equal to disabled
				message(FATAL_ERROR "3rd party program ${TOOL} is required, but was not found.")
			else()
				# we're in a submodule, and it's not required, so it's OK that the tool is not bundled
				set(${TOOL}_DISABLED TRUE)
				set(${TOOL}_ENABLED FALSE)
				
			endif()
		endif()
	
	else()
		list_contains(TOOL_REQUIRED ${TOOL} ${REQUIRED_3RDPARTY_TOOLS})
				
		if(TOOL_REQUIRED)
			message(FATAL_ERROR "3rd party program ${TOOL} is required to build Amber, but it is disabled.")
		endif()
		
		set(${TOOL}_DISABLED TRUE)
		set(${TOOL}_ENABLED FALSE)
		
	endif()	
endmacro(set_3rdparty)

#------------------------------------------------------------------------------
#  OS threading library (not really a 3rd party tool)
#------------------------------------------------------------------------------
set(CMAKE_THREAD_PREFER_PTHREAD TRUE) #Yeah, we're biased.
find_package(Threads)

# first, figure out which tools we need
# -------------------------------------------------------------------------------------------------------------------------------

# if NEEDED_3RDPARTY_TOOLS is not passed in, assume that all of them are needed
if(NOT DEFINED NEEDED_3RDPARTY_TOOLS)
	set(NEEDED_3RDPARTY_TOOLS "${3RDPARTY_TOOLS}")
endif()

if(NOT DEFINED BUNDLED_3RDPARTY_TOOLS)
	set(BUNDLED_3RDPARTY_TOOLS "")
endif()

foreach(TOOL ${3RDPARTY_TOOLS})
	list(FIND NEEDED_3RDPARTY_TOOLS ${TOOL} TOOL_INDEX)
	
	test(NEED_${TOOL} NOT "${TOOL_INDEX}" EQUAL -1)
endforeach()

if(("${NEEDED_3RDPARTY_TOOLS}" MATCHES "mkl" OR "${NEEDED_3RDPARTY_TOOLS}" MATCHES "blas" OR "${NEEDED_3RDPARTY_TOOLS}" MATCHES "lapack")
	AND NOT ("${NEEDED_3RDPARTY_TOOLS}" MATCHES "mkl" AND "${NEEDED_3RDPARTY_TOOLS}" MATCHES "blas" AND "${NEEDED_3RDPARTY_TOOLS}" MATCHES "lapack"))
	message(FATAL_ERROR "If any of mkl, blas, and lapack are put into NEEDED_3RDPARTY_TOOLS, them you must put all of them in since mkl replaces blas and lapack")
endif()

# 1st pass checking
# -------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# check if we need to use c9xcomplex
#------------------------------------------------------------------------------

if(NEED_c9x-complex)
	check_include_file(complex.h LIBC_HAS_COMPLEX)
	if(LIBC_HAS_COMPLEX)
		set_3rdparty(c9x-complex DISABLED)
	else()
		set_3rdparty(c9x-complex INTERNAL)
	endif()
endif()

#------------------------------------------------------------------------------
# check for ucpp
#------------------------------------------------------------------------------
if(NEED_ucpp)
	find_program(UCPP_LOCATION ucpp)
	
	if(${UCPP_LOCATION})
		set_3rdparty(ucpp EXTERNAL)
	else()
		set_3rdparty(ucpp INTERNAL)	#set(FIRST_RUN FALSE CACHE INTERNAL "Variable to track if it is currently the first time the build system is run" FORCE)
		
	endif()
endif()

#------------------------------------------------------------------------------
# check for byacc
# Amber needs Berkeley YACC.  It will NOT build with GNU bison.
#------------------------------------------------------------------------------
if(NEED_byacc)
	find_program(BYACC_LOCATION byacc DOC "Path to a Berkeley YACC.  GNU Bison will NOT work.")
	
	if(${BYACC_LOCATION})
		set_3rdparty(byacc EXTERNAL)
	else()
		set_3rdparty(byacc INTERNAL)
	endif()
endif()

#------------------------------------------------------------------------------
#  Readline
#------------------------------------------------------------------------------

if(NEED_readline)
	find_package(Readline)
	
	if(${READLINE_FOUND})
		set_3rdparty(readline EXTERNAL)
	else()
		#check if the internal readline has the dependencies it needs	
		find_library(TERMCAP_LIBRARY NAMES ncurses termcap)
		find_path(TERMCAP_INCLUDE_DIR termcap.h)
	
		if(${CMAKE_SYSTEM_NAME} STREQUAL Windows OR (TERMCAP_LIBRARY AND TERMCAP_INCLUDE_DIR))
			#internal readline WILL be able to build
			set_3rdparty(readline INTERNAL)
		else()
			#internal readline will NOT be able to build
			message(STATUS "Cannot use internal readline because its dependency (libtermcap/libncurses) was not found.  Set TERMCAP_LIBRARY and TERMCAP_INCLUDE_DIR to point to it.")
			set_3rdparty(readline DISABLED)
		endif()
	endif()
endif()

#------------------------------------------------------------------------------
#  MKL (near the top because it contains lapack, and blas)
#------------------------------------------------------------------------------

if(NEED_mkl)

	# We assume that most 3rd party compilers (like clang) attempt compatibility with GNU's OpenMP ABI
	test(MKL_USE_GNU_COMPAT NOT ("${CMAKE_C_COMPILER_ID}" STREQUAL "Intel" OR "${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC"))
	set(MKL_MULTI_THREADED ${OPENMP})
	
	# Static MKL is not supported at this time.
	# <long_explanation>
	# MKL has a fftw3 compatibility interface.  Wierdly enough, this interface is spread out between several different libraries: the main interface library, the 
	# cdft library, and the actual fftw3 interface library (which is distributed as source code, not a binary).
	# So, even though we don't use the fftw3 interface, there are symbols in the main MKL libraries which conflict with the symbols from fftw3.
	# Oddly, on many platforms, the linker handles this fine.  However, in at least one case (the SDSC supercomputer Comet, running a derivative of CentOS),
	# ld balks at this multiple definition, and refuses to link programs which use MKL and fftw, but ONLY when BOTH of them are built as static libraries.
	# Why this is, I'm not sure.  I do know that it's better to build fftw3 as static and use mkl as shared (because mkl is a system library)
	# then the other way around, so that's what I do
	# </long_explanation>
	set(MKL_STATIC FALSE)
	find_package(MKL)
	
	if(MKL_FOUND)
		set_3rdparty(mkl EXTERNAL)
	else()
		set_3rdparty(mkl DISABLED)
	endif()
endif()


#------------------------------------------------------------------------------
#  FFTW
#------------------------------------------------------------------------------
if(NEED_fftw)

	if(DEFINED USE_FFT AND NOT USE_FFT)
		set_3rdparty(fftw DISABLED)
	else()		
		if(MPI)
			find_package(FFTW COMPONENTS MPI Fortran)
		else()
			find_package(FFTW COMPONENTS Fortran)
		endif()
	
		if(FFTW_FOUND)
			set_3rdparty(fftw EXTERNAL)
		else()
			set_3rdparty(fftw INTERNAL)
		endif()
	endif()
endif()

#------------------------------------------------------------------------------
#  NetCDF
#------------------------------------------------------------------------------

# NetCDF is kind of a special case to the internal vs external rules.
# per https://github.com/Amber-MD/cmake-buildscripts/issues/8 , on some platforms the system installation is broken.
# So, we Amber developers have decided to make internal netcdf the default whenever possible.

# if we are just looking for NetCDF, and DON'T need fortran, then we're good to go.
if((NEED_netcdf AND NOT NEED_netcdf-fortran) AND "${BUNDLED_3RDPARTY_TOOLS}" MATCHES "netcdf")
	set_3rdparty(netcdf INTERNAL)
endif()

# if we need both and have both, also good.
if((NEED_netcdf AND NEED_netcdf-fortran) AND ("${BUNDLED_3RDPARTY_TOOLS}" MATCHES "netcdf" AND "${BUNDLED_3RDPARTY_TOOLS}" MATCHES "netcdf-fortran"))
	set_3rdparty(netcdf INTERNAL)
	set_3rdparty(netcdf-fortran INTERNAL)
endif()

# if we need both, but only have the C version, then use the internal Fortran version (not that this could be a problem if the system NetCDF is an earlier version than v4.3.0)
if((NEED_netcdf AND NEED_netcdf-fortran) AND ("${BUNDLED_3RDPARTY_TOOLS}" MATCHES "netcdf" AND NOT "${BUNDLED_3RDPARTY_TOOLS}" MATCHES "netcdf-fortran"))
	set_3rdparty(netcdf INTERNAL)
	
	find_package(NetCDF COMPONENTS F77 F90)
	if(NetCDF_F90_FOUND)
		set_3rdparty(netcdf-fortran EXTERNAL)
	else()
		set_3rdparty(netcdf-fortran DISABLED)
	endif()
	
endif()


# if we don't have bundled netcdf, then look for it externally.
# (I don't handle the case where netcdf-fortran is bundled but netcdf isn't, because that would just be weird)
if(NEED_netcdf AND NOT "${BUNDLED_3RDPARTY_TOOLS}" MATCHES "netcdf")
	
	#tell it to find the Fortran interfaces
	if(NEED_netcdf-fortran)	
		find_package(NetCDF COMPONENTS F77 F90)
	else()
		find_package(NetCDF)
	endif()
	
	if(NetCDF_FOUND)
		set_3rdparty(netcdf EXTERNAL)
	else()
		set_3rdparty(netcdf DISABLED)
	endif()
	
	if(NEED_netcdf-fortran)
		if(NetCDF_F90_FOUND)
			set_3rdparty(netcdf-fortran EXTERNAL)
		else()
			set_3rdparty(netcdf-fortran DISABLED)
		endif()
	endif()
endif()

#------------------------------------------------------------------------------
#  XBlas
#------------------------------------------------------------------------------

if(NEED_xblas)
	#NOTE: xblas is currently only available as a static library.
	# however, it will need to be built with PIC turned on if amber is built as shared
	find_library(XBLAS_LIBRARY NAMES xblas-amb xblas)
	
	if(XBLAS_LIBRARY)
		set_3rdparty(xblas EXTERNAL)
	elseif(CAN_BUILD_AUTOMAKE)
		set_3rdparty(xblas INTERNAL)
	else()
		set_3rdparty(xblas DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  Netlib libraries
#------------------------------------------------------------------------------

if(NEED_blas) # because of the earlier check, we can be sure that NEED_blas == NEED_lapack

	if(mkl_ENABLED)
		set_3rdparty(blas DISABLED)
		set_3rdparty(lapack DISABLED)
	else()
		# this calls FindBLAS
		find_package(LAPACKFixed)
		
		if(BLAS_FOUND)
			set_3rdparty(blas EXTERNAL)
		else()
			set_3rdparty(blas INTERNAL)
		endif()
		
		if(LAPACK_FOUND)
			set_3rdparty(lapack EXTERNAL)
		else()
			set_3rdparty(lapack INTERNAL)
		endif()
	endif()
endif()

if(NEED_arpack)
	#  ARPACK
	find_library(ARPACK_LIBRARY arpack)
	if(ARPACK_LIBRARY)
		set_3rdparty(arpack EXTERNAL)
	else()
		set_3rdparty(arpack INTERNAL)
	endif()
endif()

# --------------------------------------------------------------------
#  Parallel NetCDF
# --------------------------------------------------------------------

if(NEED_pnetcdf)
	if(MPI)
		find_package(PnetCDF COMPONENTS C)
		
		if(PnetCDF_C_FOUND)
			set_3rdparty(pnetcdf EXTERNAL)
		else()
			set_3rdparty(pnetcdf INTERNAL)
		endif()
	else()
		set_3rdparty(pnetcdf DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  APBS
#------------------------------------------------------------------------------

if(NEED_apbs)

	find_package(APBS)	#set(FIRST_RUN FALSE CACHE INTERNAL "Variable to track if it is currently the first time the build system is run" FORCE)
	
	if(APBS_FOUND)
		set_3rdparty(apbs EXTERNAL)
	else()
		set_3rdparty(apbs DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  PUPIL
#------------------------------------------------------------------------------

if(NEED_pupil)
	find_package(PUPIL)
	if(PUPIL_FOUND)
		set_3rdparty(pupil EXTERNAL)
	else()
		set_3rdparty(pupil DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  LIO
#------------------------------------------------------------------------------

if(NEED_lio)

	#with the old system, lio was found by pointing configure to its source directory
	#we support the same argument, and we look for the libraries in the system search path
	if(DEFINED LIO_HOME)
		find_library(LIO_G2G_LIBRARY NAMES g2g PATHS ${LIO_HOME}/g2g DOC "Path to libg2g.so")
		find_library(LIO_AMBER_LIBRARY NAMES lio-g2g PATHS ${LIO_HOME}/lioamber DOC "Path to liblio-g2g.so")
	else()
		find_library(LIO_G2G_LIBRARY g2g DOC "Path to libg2g.so")
		find_library(LIO_AMBER_LIBRARY lio-g2g DOC "Path to liblio-g2g.so")
	endif()
	
	if(LIO_G2G_LIBRARY AND LIO_G2G_LIBRARY)	
		message(STATUS "Found lio!")
		
		set_3rdparty(lio EXTERNAL)
	else()	
		message(STATUS "Could not find lio.  If you want to use it, set LIO_HOME to point to a built lio source directory.")
		
		set_3rdparty(lio DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
# PLUMED
#------------------------------------------------------------------------------

if(NEED_plumed)

	# plumed can be loaded one of three ways: static linking, dynamic linking, or runtime linking using dlopen
	if(DEFINED PLUMED_ROOT)
		find_path(PLUMED_INSTALL_DIR NAMES lib/plumed/src/lib/Plumed.cmake PATHS ${PLUMED_ROOT} DOC "Directory plumed is installed to.  Should contain lib/plumed/src/lib/Plumed.cmake")
	else()
		find_path(PLUMED_INSTALL_DIR NAMES lib/plumed/src/lib/Plumed.cmake DOC "Directory plumed is installed to.  Should contain lib/plumed/src/lib/Plumed.cmake")
	endif()
	
	
	if(PLUMED_INSTALL_DIR)
		message(STATUS "Found PLUMED, linking to it at build time.")
		
		set_3rdparty(plumed EXTERNAL)
		
	else()
	
		set_3rdparty(plumed DISABLED)
	
	endif()
endif()

#------------------------------------------------------------------------------
#  zlib, for cpptraj and netcdf
#------------------------------------------------------------------------------

if(NEED_zlib)
	find_package(ZLIB)
	
	if(ZLIB_FOUND)
		set_3rdparty(zlib EXTERNAL)
	else()
		set_3rdparty(zlib DISABLED)  # will always error
	endif()
endif()

#------------------------------------------------------------------------------
#  bzip2
#------------------------------------------------------------------------------
if(NEED_libbz2)
	find_package(BZip2)
	
	
	if(BZIP2_FOUND)
		set_3rdparty(libbz2 EXTERNAL)
	else()
		set_3rdparty(libbz2 DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  Math library
#------------------------------------------------------------------------------ 

if(NEED_libm)
	# figure out if we need a math library
	# we actually need to be a little careful here, because most of the math.h functions are defined as GCC intrinsics, so check_function_exists() might not find them.
	# So, we use this c source instead
	set(CMAKE_REQUIRED_LIBRARIES "")
	set(CHECK_SINE_C_SOURCE "#include <math.h>
	
	int main(int argc, char** args)
	{
		return sin(argc - 1);
	}")
	
	check_c_source_compiles("${CHECK_SINE_C_SOURCE}" STDLIB_HAVE_SIN)
	
	if(STDLIB_HAVE_SIN)
		message(STATUS "Found math library functions in standard library.")
		set(LIBM "")
	else()
		find_library(LIBM NAMES m math libm)
		if(LIBM)
			set(CMAKE_REQUIRED_LIBRARIES ${LIBM})
			check_c_source_compiles("${CHECK_SINE_C_SOURCE}" LIBM_HAVE_SIN)
	
			if(LIBM_HAVE_SIN)
				message(STATUS "Found math library functions in math library \"${LIBM}\".")
			else()
				# Cause the try_compile to be retried
				unset(LIBM_HAVE_SIN CACHE)
				message(FATAL_ERROR "Could not find math functions in the standard library or the math library \"${LIBM}\".  Please set the LIBM variable to point to the library containing these functions.")
			endif()
		else()
			message(FATAL_ERROR "Could not find math functions in the standard library.  Please set the LIBM variable to point to the library containing these functions.")
		endif()
	endif()
	
	if(NOT STDLIB_HAVE_SIN)
		list(APPEND REQUIRED_3RDPARTY_TOOLS libm)
	endif()
			
	if(LIBM AND NOT STDLIB_HAVE_SIN)
		set_3rdparty(libm EXTERNAL)
	else()
		set_3rdparty(libm DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  QT4 (used by MTK++)
#------------------------------------------------------------------------------
if(NEED_qt4)
	set(QT4_NO_LINK_QTMAIN TRUE)
	set(CMAKE_AUTOMOC FALSE)
	find_package(Qt4)
	
	if(Qt4_FOUND)
		set_3rdparty(qt4 EXTERNAL)
	else()
		set_3rdparty(qt4 DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  log4cxx (used by MTK++)
#------------------------------------------------------------------------------
if(NEED_log4cxx)
	find_package(log4cxx)
	
	if(LOG4CXX_FOUND)
		set_3rdparty(log4cxx EXTERNAL)
	else()
		set_3rdparty(log4cxx DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  mpi4py (only needed for MMPBSA.py)
#------------------------------------------------------------------------------
if(NEED_mpi4py)

	if(MPI AND (BUILD_PYTHON AND NOT CROSSCOMPILE))
		check_python_package(mpi4py MPI4PY_FOUND)
		if(MPI4MPY_FOUND)
			set_3rdparty(mpi4py EXTERNAL)
		else()
			set_3rdparty(mpi4py INTERNAL)
		endif()
	else()
		set_3rdparty(mpi4py DISABLED)
	endif()
endif()

#------------------------------------------------------------------------------
#  PerlMol
#------------------------------------------------------------------------------
if(NEED_perlmol)
	
	if(BUILD_PERL)
		find_package(PerlModules COMPONENTS Chemistry::Mol)
				
		if(EXISTS "${PERLMODULES_CHEMISTRY_MOL_MODULE}")
			set_3rdparty(perlmol EXTERNAL)
		else()
			if(HAVE_PERL_MAKE)
				set_3rdparty(perlmol INTERNAL)
			else()
				message(STATUS "Cannot build PerlMol internally because PERL_MAKE is not set to a valid program.")
				set_3rdparty(perlmol DISABLED)
			endif()
		endif()
		
	else()
		set_3rdparty(perlmol DISABLED)
	endif()
endif()

# Apply user overrides
# -------------------------------------------------------------------------------------------------------------------------------------------------------

set(FORCE_EXTERNAL_LIBS "" CACHE STRING "3rd party libraries to force using the system version of. Accepts a semicolon-seperated list of library names from the 3rd Party Libraries section of the build report.")
set(FORCE_INTERNAL_LIBS "" CACHE STRING "3rd party libraries to force to build inside Amber. Accepts a semicolon-seperated list of library names from the 3rd Party Libraries section of the build report.")
set(FORCE_DISABLE_LIBS "" CACHE STRING "3rd party libraries to force Amber to not use at all. Accepts a semicolon-seperated list of library names from the 3rd Party Libraries section of the build report.")

foreach(TOOL ${FORCE_EXTERNAL_LIBS})
	colormsg(GREEN "Forcing ${TOOL} to be sourced externally")

	list_contains(VALID_TOOL ${TOOL} ${3RDPARTY_TOOLS})
	
	if(NOT VALID_TOOL)
		message(FATAL_ERROR "${TOOL} is not a valid 3rd party library name.")
	endif()
	
	set_3rdparty(${TOOL} EXTERNAL)
endforeach()

if(INSIDE_AMBER)
	foreach(TOOL ${FORCE_INTERNAL_LIBS})
		colormsg(YELLOW "Forcing ${TOOL} to be built internally")
	
		list_contains(VALID_TOOL ${TOOL} ${3RDPARTY_TOOLS})
		
		if(NOT VALID_TOOL)
			message(FATAL_ERROR "${TOOL} is not a valid 3rd party library name.")
		endif()
		
		set_3rdparty(${TOOL} INTERNAL)
	endforeach()
endif()

foreach(TOOL ${FORCE_DISABLE_LIBS})
	colormsg(HIRED "Forcing ${TOOL} to be disabled")

	list_contains(VALID_TOOL ${TOOL} ${3RDPARTY_TOOLS})
	
	if(NOT VALID_TOOL)
		message(FATAL_ERROR "${TOOL} is not a valid 3rd party library name.")
	endif()
	
	set_3rdparty(${TOOL} DISABLED)
endforeach()

# force all unneeded tools to be disabled
foreach(TOOL ${3RDPARTY_TOOLS})
	list(FIND NEEDED_3RDPARTY_TOOLS ${TOOL} TOOL_INDEX)
	
	if(${TOOL_INDEX} EQUAL -1)
		set_3rdparty(${TOOL} DISABLED)
	endif()
	
endforeach()

# check math library configuration
if(LINALG_LIBS_REQUIRED AND NOT (mkl_ENABLED OR (blas_ENABLED AND lapack_ENABLED)))
	message(FATAL_ERROR "You must enable a linear algebra library -- either blas and lapack, or mkl")
endif()

if(mkl_ENABLED AND (blas_ENABLED AND lapack_ENABLED))
	message(FATAL_ERROR "You cannot use MKL and regular blas/lapack at the same time!")
endif()

# Now that we know which libraries we need, set them up properly.
# -------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# c9xcomplex
#------------------------------------------------------------------------------

if(c9x-complex_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS c9x-complex)
endif()

#------------------------------------------------------------------------------
# check ucpp, import the system version
#------------------------------------------------------------------------------
if(ucpp_EXTERNAL)
	import_executable(ucpp ${UCPP_LOCATION})
elseif(ucpp_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS ucpp-1.3)
endif()

#------------------------------------------------------------------------------
# byacc
#------------------------------------------------------------------------------
if(byacc_EXTERNAL)
	import_executable(byacc ${UCPP_LOCATION})	
elseif(byacc_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS byacc)
endif()

#------------------------------------------------------------------------------
#  Readline
#------------------------------------------------------------------------------

if(readline_EXTERNAL)
	import_library(readline ${READLINE_LIBRARY} ${READLINE_INCLUDE_DIR} ${READLINE_INCLUDE_DIR}/readline)	
	
	# Configure dll imports if neccesary
	# It's not like this is, y'know, DOCUMENTED anywhere
	if(TARGET_WINDOWS)
		get_lib_type(${READLINE_LIBRARY} READLINE_LIB_TYPE)
		if("${READLINE_LIB_TYPE}" STREQUAL "STATIC")
			set_property(TARGET readline PROPERTY INTERFACE_COMPILE_DEFINITIONS USE_READLINE_STATIC)
		else()
			set_property(TARGET readline PROPERTY INTERFACE_COMPILE_DEFINITIONS USE_READLINE_DLL)
		endif()
	endif()
elseif(readline_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS readline)
endif()

#------------------------------------------------------------------------------
#  MKL
#------------------------------------------------------------------------------


if(mkl_ENABLED)
	if(NOT MKL_FOUND)
		message(FATAL_ERROR "You enabled MKL, but it was not found.")
	endif()
	
	if(MIXING_COMPILERS AND OPENMP)
		message(WARNING "You are using different compilers from different vendors together.  This may cause link errors with MKL and OpenMP.  There is no way around this.")
	endif()
	
	if(OPENMP AND NOT ("${CMAKE_C_COMPILER_ID}" STREQUAL GNU OR "${CMAKE_C_COMPILER_ID}" STREQUAL Intel))
		message(WARNING "Using MKL in OpenMP mode probably will not work with compilers other than GCC or Intel.")
	endif()
	
	if(mkl_ENABLED AND (blas_ENABLED OR lapack_ENABLED))
		message(FATAL_ERROR "MKL replaces blas and lapack!  They can't be enabled when MKL is in use!")
	endif()
	
	# add to library tracker
	import_libraries(mkl LIBRARIES ${MKL_FORTRAN_LIBRARIES} INCLUDES ${MKL_INCLUDE_DIRS})
endif()

#------------------------------------------------------------------------------
#  FFTW
#------------------------------------------------------------------------------

if(fftw_EXTERNAL)
	
	if(NOT FFTW_FOUND)
		message(FATAL_ERROR "Could not find FFTW, but it was set so be sourced externally!")
	endif()

	# Import the system fftw as a library
	import_library(fftw ${FFTW_LIBRARIES_SERIAL} ${FFTW_INCLUDES_SERIAL})
	
	get_lib_type(${FFTW_LIBRARIES_SERIAL} EXT_FFTW_LIB_TYPE)
	
	# if we are using a Windows DLL, define the correct import macros
	if(TARGET_WINDOWS AND NOT ("${EXT_FFTW_LIB_TYPE}" STREQUAL "STATIC"))
		set_property(TARGET fftw PROPERTY INTERFACE_COMPILE_DEFINITIONS FFTW_DLL CALLING_FFTW)
	endif()

	if(MPI)
		# Import MPI fftw
		import_library(fftw_mpi ${FFTW_LIBRARIES_MPI} ${FFTW_INCLUDES_MPI})
		
	endif()	
	
elseif(fftw_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS fftw-3.3)
endif()


#------------------------------------------------------------------------------
#  NetCDF
#------------------------------------------------------------------------------

if(netcdf_EXTERNAL)
	
	if(NOT NetCDF_FOUND)
		message(FATAL_ERROR "netcdf was set to be sourced externally, but it was not found!")
	endif()
	
	# Import the system netcdf as a library
	import_library(netcdf ${NetCDF_LIBRARIES_C} ${NetCDF_INCLUDES})
	
elseif(netcdf_INTERNAL)

	#TODO on Cray systems a static netcdf may be required

	if(${COMPILER} STREQUAL cray)
			message(FATAL_ERROR "Bundled NetCDF cannot be used with cray compilers.  Please reconfigure with -DFORCE_EXTERNAL_LIBS=netcdf. \
		 On cray systems you can usually load the system NetCDF with 'module load cray-netcdf' or 'module load netcdf'.")
	endif()
		
	list(APPEND 3RDPARTY_SUBDIRS netcdf-4.3.0)
endif()

if(netcdf-fortran_EXTERNAL)

	if(NOT NetCDF_F90_FOUND)
		message(FATAL_ERROR "netcdf-fortran was set to be sourced externally, but it was not found!")
	endif()
	
	# Import the system netcdf as a library
	import_library(netcdff ${NetCDF_LIBRARIES_F90} ${NetCDF_INCLUDES})
	set_property(TARGET netcdff PROPERTY INTERFACE_LINK_LIBRARIES netcdf)
	
	# This is really for symmetry with the other MOD_DIRs more than anything.
	set(NETCDF_FORTRAN_MOD_DIR ${NetCDF_INCLUDES})
	
elseif(netcdf-fortran_INTERNAL)
	#TODO on Cray systems a static netcdf may be required

	if(${COMPILER} STREQUAL cray)
			message(FATAL_ERROR "Bundled NetCDF cannot be used with cray compilers. \
 On cray systems you can usually load the system NetCDF with 'module load cray-netcdf' or 'module load netcdf'.")
	endif()

	list(APPEND 3RDPARTY_SUBDIRS netcdf-fortran-4.4.4)
endif()


#------------------------------------------------------------------------------
#  XBlas
#------------------------------------------------------------------------------

if(xblas_EXTERNAL)
	import_library(xblas ${XBLAS_LIBRARY})
	
elseif(xblas_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS xblas)
	
endif()

#------------------------------------------------------------------------------
#  Netlib libraries
#------------------------------------------------------------------------------

# BLAS
if(blas_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS blas)
elseif(blas_EXTERNAL)
	import_libraries(blas LIBRARIES "${BLAS_LIBRARIES}")
endif()

#  LAPACK
if(lapack_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS lapack)
elseif(lapack_EXTERNAL)
	import_libraries(lapack LIBRARIES "${LAPACK_LIBRARIES}")
endif()


#  ARPACK
if(arpack_EXTERNAL)
	if(NOT EXISTS "${ARPACK_LIBRARY}")
		message(FATAL_ERROR "arpack was set to be sourced externally, but it was not found!")
	endif()
	
	import_library(arpack ${ARPACK_LIBRARY})

	set(CMAKE_REQUIRED_LIBRARIES ${ARPACK_LIBRARY})

	#Some arpacks (e.g. Ubuntu's package manager's one) don't have the arsecond_ function from wallclock.c
	#sff uses it, so we have to tell sff to build it
	check_function_exists(arsecond_ ARPACK_HAS_ARSECOND)
	set(CMAKE_REQUIRED_LIBRARIES "")

	if(NOT ARPACK_HAS_ARSECOND)
		message(STATUS "System arpack is missing the arsecond_ function.  That function will be built inside amber")
	endif()

elseif(arpack_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS arpack)
endif()
	
# --------------------------------------------------------------------
#  Parallel NetCDF
# --------------------------------------------------------------------

if(pnetcdf_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS pnetcdf)
elseif(pnetcdf_EXTERNAL)
	if(NOT PnetCDF_C_FOUND)
		message(FATAL_ERROR "You requested to use an external pnetcdf, but no installation was found.")
	endif()
	
	import_library(pnetcdf ${PnetCDF_C_LIBRARY} ${PnetCDF_C_INCLUDES})
	
endif()

#------------------------------------------------------------------------------
#  APBS
#------------------------------------------------------------------------------

if(apbs_EXTERNAL)
	if(NOT APBS_FOUND)
		message(FATAL_ERROR "You requested to use external apbs, but no installation was found.")
	endif()

	import_libraries(apbs LIBRARIES ${APBS_LIBRARIES})
endif()

#------------------------------------------------------------------------------
#  PUPIL
#------------------------------------------------------------------------------

if(pupil_EXTERNAL)
	import_libraries(pupil LIBRARIES ${PUPIL_LIBRARIES})
endif()

#------------------------------------------------------------------------------
#  LIO
#------------------------------------------------------------------------------

if(lio_EXTERNAL)
	import_libraries(lio LIBRARIES ${LIO_AMBER_LIBRARY} ${LIO_G2G_LIBRARY})	
endif()

#------------------------------------------------------------------------------
# PLUMED
#------------------------------------------------------------------------------
if(plumed_EXTERNAL)
	include(${PLUMED_INSTALL_DIR}/lib/plumed/src/lib/Plumed.cmake)
	
	if(STATIC)
		#build the multiple object files it installs (???) into a single archive
		add_library(plumed STATIC ${PLUMED_STATIC_DEPENDENCIES})
		install_libraries(plumed)
	else()
		import_library(plumed ${PLUMED_SHARED_DEPENDENCIES})
	endif()
	
	set(PLUMED_RUNTIME_LINK FALSE)	
	
	
else()
	if(HAVE_LIBDL AND NEED_plumed)
		message(STATUS "Cannot find PLUMED.  You will still be able to load it at runtime.  If you want to link it at build time, set PLUMED_ROOT to where you installed it.")
		
		set(PLUMED_RUNTIME_LINK TRUE)
	else()		
		set(PLUMED_RUNTIME_LINK FALSE)
	endif()
endif()

#------------------------------------------------------------------------------
# libbz2
#------------------------------------------------------------------------------

if(libbz2_EXTERNAL)
	import_library(bzip2 ${BZIP2_LIBRARIES} ${BZIP2_INCLUDE_DIR})
endif()

#------------------------------------------------------------------------------
# zlib
#------------------------------------------------------------------------------
if(zlib_EXTERNAL)
	import_libraries(zlib LIBRARIES ${ZLIB_LIBRARIES} INCLUDES ${ZLIB_INCLUDE_DIR})
endif()

#------------------------------------------------------------------------------
#  Math library
#------------------------------------------------------------------------------ 
if(libm_EXTERNAL)	
	import_library(libm ${LIBM})
endif()

#------------------------------------------------------------------------------
#  log4cxx
#------------------------------------------------------------------------------ 
if(log4cxx_EXTERNAL)
	import_library(log4cxx ${LOG4CXX_LIBRARY} ${LOG4CXX_INCLUDE_DIR})
endif()

#------------------------------------------------------------------------------
#  Qt4
#------------------------------------------------------------------------------ 

if(qt4_ENABLED)
	# MTKpp uses qt4's XML parser, so we need to add it to the library tracker
	get_property(QT4_XML_IMPORTED_LOCATION TARGET Qt4::QtXml PROPERTY IMPORTED_LOCATION_RELEASE)
	using_external_library(${QT4_XML_IMPORTED_LOCATION})
endif()

#------------------------------------------------------------------------------
#  mpi4py
#------------------------------------------------------------------------------ 

if(mpi4py_EXTERNAL)
	if(NOT MPI4PY_FOUND)
		message(FATAL_ERROR "mpi4py was set to be sourced externally, but the mpi4py package was not found.")
	endif()
elseif(mpi4py_INTERNAL)
	list(APPEND 3RDPARTY_SUBDIRS mpi4py-2.0.0)
endif()

#------------------------------------------------------------------------------
#  perlmol
#------------------------------------------------------------------------------

if(perlmol_EXTERNAL)
	 if(NOT EXISTS "${PERLMODULES_CHEMISTRY_MOL_MODULE}")
		message(FATAL_ERROR "The Chemistry::Mol perl package was set to be sourced externally, but it was not found.")
	endif()
elseif(perlmol_INTERNAL)
	
	if(NOT HAVE_PERL_MAKE)
		message(FATAL_ERROR "A perl-compatible make program (DMake on Windows) is required to build Chemistry::Mol")
	endif()
	list(APPEND 3RDPARTY_SUBDIRS PerlMol-0.3500)
endif()