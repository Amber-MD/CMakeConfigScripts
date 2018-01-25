#File which sets special compiler flags for PMEMD
#Often little configuration things are done in the subdir CMakeLists, but since the logic is so complicated I wanted to do this here in the root folder


#Configuration for Intel's MIC processors.

option(MIC "Build for Intel Many Integrated Core processors (Xeon Phi and Knight's Landing)." FALSE)
set(MIC_TYPE "PHI" CACHE STRING "Type of MIC to build.  Options: PHI, PHI_OFFLOAD, KNIGHTS_LANDING, KNIGHTS_LANDING_SPDP.  Only does anything if MIC is enabled.")
validate_configuration_enum(MIC_TYPE PHI PHI_OFFLOAD KNIGHTS_LANDING KNIGHTS_LANDING_SPDP)

#NOTE: in the configure script, MIC_PHI is called mic, and MIC_KL is called mic2
set(MIC_PHI FALSE)
set(MIC_KL FALSE)

if(MIC AND ${MIC_TYPE} MATCHES "PHI.*")
	set(MIC_PHI TRUE)
elseif(MIC)
	set(MIC_KL FALSE)
endif()

#-------------------------------------------------------------------------------
#  Set default flags.  
#-------------------------------------------------------------------------------
set(PMEMD_C_DEFINITIONS "")
set(PMEMD_F_DEFINITIONS "")

set(PMEMD_CFLAGS "")
set(PMEMD_FFLAGS "")

set(PMEMD_NO_OPT_CFLAGS -O0 -g)
set(PMEMD_NO_OPT_FFLAGS -O0 -g)
set(PMEMD_NO_OPT_CXXFLAGS -O0 -g)

set(EMIL_MIC_DEFS "")
set(EMIL_MIC_FLAGS "")

#-------------------------------------------------------------------------------
#  CUDA precisions
#  For each value in theis variable, the CUDA code will be built again with use_<value> defined,
#  and a new pmemd.<value> executable will be created
#-------------------------------------------------------------------------------

set(PMEMD_CUDA_PRECISIONS SPFP DPFP SPXP)

#precision of pmemd which gets installed as pmemd.cuda
set(PMEMD_DEFAULT_PRECISION SPFP)

#-------------------------------------------------------------------------------
# Optimization flag configuration  
#-------------------------------------------------------------------------------

if(${CMAKE_C_COMPILER_ID} STREQUAL "Intel")

	if(MIC_PHI AND  ${CMAKE_C_COMPILER_ID} VERSION_LESS 12)
		message(FATAL_ERROR "Building for Xeon Phi requires Intel Compiler Suite v12 or later.")
	endif()

    # RCW Removed 10/5/2010 - Causes issues building in parallel since -fast always implies -static.
    #pmemd_foptflags='-fast'
    #pmemd_coptflags='-fast'

    # BPR: Note: -fast implies the use of these flags:
    #
    # Intel 11
    # --------
    # Mac: -ipo -O3 -mdynamic-no-pic -no-prec-div -static -xHost
    # IA-64 Linux: -ipo -O3 -static
    # IA-32/Intel-64 Linux: -ipo -O3 -no-prec-div -static -xHost
    #
    # Intel 10
    # --------
    # Mac: -ipo -O3 -mdynamic-no-pic -no-prec-div -static -xP (ifort),
    #      -ipo -O3 -mdynamic-no-pic -no-prec-div (icc)
    # IA-64 Linux: -ipo -O3 -static
    # IA-32/Intel-64 Linux: -ipo -O3 -no-prec-div -static -xP
      
	if(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
	
		set(PMEMD_CFLAGS -O3 -mdynamic-no-pic -no-prec-div)
		
		# -ipo (multi-file Interprocedural Optimizations optimizations) causes issues with
      	#  CUDA c code linking. Leave at a single-file IPO for the moment MJW
      
      	if(CUDA)
      		list(APPEND PMEMD_CFLAGS -ip)
      	else()
      		list(APPEND PMEMD_CFLAGS -ipo)
      	endif()
      	
      
		if(${CMAKE_C_COMPILER_VERSION} VERSION_GREATER 11 OR ${CMAKE_C_COMPILER_VERSION} VERSION_EQUAL 11)
			list(APPEND PMEMD_CFLAGS -xHost)
		endif()
	else()
		set(PMEMD_CFLAGS -ip -O3 -no-prec-div)
		

		if(MIC AND (${MIC_TYPE} STREQUAL "PHI_OFFLOAD"))
		
			list(APPEND PMEMD_CFLAGS -xHost)
			
		elseif(NOT MIC_PHI)
		
			if(${CMAKE_C_COMPILER_VERSION} VERSION_GREATER 11 OR ${CMAKE_C_COMPILER_VERSION} VERSION_EQUAL 11)
			
				if(SSE)
					if(NOT "${SSE_TYPES}" STREQUAL "")
						list(APPEND PMEMD_CFLAGS "-ax${SSE_TYPES}")
					else()
						list(APPEND PMEMD_CFLAGS -xHost)
					endif()
				endif()
				
			else()
			
				if(SSE)
					list(APPEND PMEMD_CFLAGS -axSTPW)
				endif()
				
			endif()
		endif()
	endif()
	
	if(MIC_PHI)
		list(APPEND PMEMD_CFLAGS -mmic)
	elseif(MIC_KL)
		if(INTELMPI AND OPENMP)
			list(APPEND PMEMD_C_DEFINITIONS MIC2)
			if(${CMAKE_C_COMPILER_VERSION} VERSION_GREATER 12 AND ${CMAKE_C_COMPILER_VERSION} VERSION_LESS 16)
				list(APPEND PMEMD_CFLAGS -openmp-simd)
			else()
				list(APPEND PMEMD_CFLAGS -qopenmp-simd)
			endif()
			
			if(${MIC_TYPE} STREQUAL "KNIGHTS_LANDING_SPDP")
				list(APPEND PMEMD_C_DEFINITIONS pmemd_SPDP) 
				
				if(NOT mkl_ENABLED)
					message(FATAL_ERROR "Cannot use KNIGHTS_LANDING_SPDP optimizations without Intel MPI, Intel OpenMP, and Intel MKL on.  Please enable it, or turn off SPDP!")
				endif()
			else()
				list(APPEND PMEMD_C_DEFINITIONS pmemd_DPDP)
			endif()
		else()
			message(FATAL_ERROR "Cannot use MIC2 optimizations without Intel MPI & OpenMP on.  Pleas pass -DOPENMP=TRUE -DMPI=TRUE and provide an intel MPI library.")
		endif()
	endif()
	
	if(MIC_PHI AND (${MIC_TYPE} STREQUAL "PHI_OFFLOAD"))
		list(APPEND PMEMD_C_DEFINITIONS MIC_offload)
		list(APPEND PMEMD_CFLAGS -opt-streaming-cache-evict=0 -fimf-domain-exclusion=15)
	endif()	
else()
	#use regular compiler optimization flags
	set(PMEMD_CFLAGS ${OPT_CFLAGS})
endif()

#Fortran
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

#this tree mirrors the C tree very closely, with only minor differences
if("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "Intel")
	if(MIC_PHI AND  "${CMAKE_Fortran_COMPILER_VERSION}" VERSION_LESS 12)
		message(FATAL_ERROR "Building for Xeon Phi requires Intel Compiler Suite v12 or later.")
	endif()
	
	if(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
	
		set(PMEMD_FFLAGS -O3 -mdynamic-no-pic -no-prec-div)
		
		# -ipo (multi-file Interprocedural Optimizations optimizations) causes issues with
      	#  CUDA c code linking. Leave at a single-file IPO for the moment MJW
      
      	if(CUDA)
      		list(APPEND PMEMD_FFLAGS -ip)
      	else()
      		list(APPEND PMEMD_FFLAGS -ipo)
      	endif()
      	
      
		if("${CMAKE_Fortran_COMPILER_VERSION}" VERSION_GREATER 11 OR ${CMAKE_Fortran_COMPILER_VERSION} VERSION_EQUAL 11)
			list(APPEND PMEMD_FFLAGS -xHost)
		endif()
	else()
		set(PMEMD_FFLAGS -ip -O3 -no-prec-div)

		if(MIC AND (${MIC_TYPE} STREQUAL "PHI_OFFLOAD"))
		
			list(APPEND PMEMD_FFLAGS -xHost)
			
		elseif(NOT MIC_PHI)
		
			if("${CMAKE_Fortran_COMPILER_VERSION}" VERSION_GREATER 11 OR ${CMAKE_Fortran_COMPILER_VERSION} VERSION_EQUAL 11)
			
				if(SSE)
					if(NOT "${SSE_TYPES}" STREQUAL "")
						list(APPEND PMEMD_FFLAGS "-ax${SSE_TYPES}")
					else()
						list(APPEND PMEMD_FFLAGS -xHost)
					endif()
				endif()
				
			else()
			
				if(SSE)
					list(APPEND PMEMD_FFLAGS -axSTPW)
				endif()
				
			endif()
		endif()
	endif()
	
	if(MIC_PHI)
		list(APPEND PMEMD_FFLAGS -mmic)
	elseif(MIC_KL)
		if(INTELMPI AND OPENMP)
			list(APPEND PMEMD_F_DEFINITIONS MIC2)
			if("${CMAKE_Fortran_COMPILER_VERSION}" VERSION_GREATER 12 AND ${CMAKE_Fortran_COMPILER_VERSION} VERSION_LESS 16)
				list(APPEND PMEMD_FFLAGS -openmp-simd)
			else()
				list(APPEND PMEMD_FFLAGS -qopenmp-simd)
			endif()
			
			if(${MIC_TYPE} STREQUAL "KNIGHTS_LANDING_SPDP")
				list(APPEND PMEMD_F_DEFINITIONS pmemd_SPDP faster_MIC2) 
				
				if(NOT mkl_ENABLED)
					message(FATAL_ERROR "Cannot use KNIGHTS_LANDING_SPDP optimizations without Intel MPI, Intel OpenMP, and Intel MKL on.  Please enable it, or turn off SPDP!")
				endif()
			else()
				list(APPEND PMEMD_F_DEFINITIONS pmemd_DPDP)
			endif()
		else()
			message(FATAL_ERROR "Cannot use MIC2 optimizations without Intel MPI & OpenMP on.  Please pass -DOPENMP=TRUE -DMPI=TRUE and provide an intel MPI library.")
		endif()
	endif()
	
	if(MIC_PHI AND (${MIC_TYPE} STREQUAL "PHI_OFFLOAD"))
		list(APPEND PMEMD_F_DEFINITIONS MIC_offload)
		list(APPEND PMEMD_FFLAGS -opt-streaming-cache-evict=0 -fimf-domain-exclusion=15 -align array64byte)
	endif()	
elseif("${CMAKE_Fortran_COMPILER_ID}" STREQUAL PGI)
	set(PMEMD_FFLAGS -O4 -fastsse -Munroll -Mnoframe -Mscalarsse -Mvect=sse -Mcache_align)
else()
	#use regular compiler flags
	set(PMEMD_FFLAGS ${OPT_FFLAGS})
endif()


#C++
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Configure EMIL CXXFLAGS
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
	
	if(MIC_PHI AND ${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS 12)
		message(FATAL_ERROR "Building for Xeon Phi requires Intel Compiler Suite v12 or later.")
	endif()

	if(MIC)
		list(APPEND EMIL_MIC_FLAGS -mmic)
		
		if(MIC_PHI AND (${MIC_TYPE} STREQUAL "PHI_OFFLOAD"))
			list(APPEND EMIL_MIC_DEFS MIC_offload)
			list(APPEND EMIL_MIC_FLAGS -opt-streaming-cache-evict=0 -fimf-domain-exclusion=15)
		endif()	
	endif()
endif()
	
if("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "GNU" AND "${CMAKE_Fortran_COMPILER_VERSION}" VERSION_EQUAL 5)	
	# compile pmemd prmtop_dat at lower optimization for buggy gnu 5.x: see bug 303.
	set(PMEMD_GNU_BUG_303 TRUE) 
else()
	set(PMEMD_GNU_BUG_303 FALSE)
endif()


# use debugging flags in debug configuration
if(NOT OPTIMIZE)
	set(PMEMD_CFLAGS ${PMEMD_NO_OPT_CFLAGS})
	set(PMEMD_FFLAGS ${PMEMD_NO_OPT_FFLAGS})
endif()

# create non-list versions for PROPERTY COMPILE_FLAGS
list_to_space_separated(PMEMD_CFLAGS_SPC ${PMEMD_CFLAGS})
list_to_space_separated(PMEMD_FFLAGS_SPC ${PMEMD_FFLAGS})


#-------------------------------------------------------------------------------
#  CUDA configuration
#-------------------------------------------------------------------------------

option(GTI "Use GTI version of pmemd.cuda instead of AFE version" FALSE)

if(CUDA)
	set(PMEMD_NVCC_FLAGS -use_fast_math -O3)
	
	set(PMEMD_CUDA_DEFINES -DCUDA)
	
	if(GTI)
		
		list(APPEND PMEMD_NVCC_FLAGS -rdc=true --std c++11) 
		list(APPEND PMEMD_CUDA_DEFINES -DGTI)
		
		message(STATUS "Building the GTI version of pmemd.cuda")
	else()
		message(STATUS "Building the AFE version of pmemd.cuda")
	endif()

	if(MPI)
		list(APPEND PMEMD_NVCC_FLAGS -DMPICH_IGNORE_CXX_SEEK)
	endif()
	
	# Before CMake 3.7, FindCUDA did not automatically link libcudadevrt, as is required for seperable compilation.
	# Finder code copied from here: https://github.com/Kitware/CMake/commit/891e0ebdcea547b10689eee9fd008a27e4afd3b9
	if(CMAKE_VERSION VERSION_LESS 3.7)
		cuda_find_library_local_first(CUDA_cudadevrt_LIBRARY cudadevrt "\"cudadevrt\" library")
 		mark_as_advanced(CUDA_cudadevrt_LIBRARY)
 	endif()
endif()

#-------------------------------------------------------------------------------
#  MKL configuration
#-------------------------------------------------------------------------------

# tell PMEMD to use MKL if it's installed
if(mkl_ENABLED)
	list(APPEND PMEMD_F_DEFINITIONS FFTW_FFT MKL_FFTW_FFT)
else()
	list(APPEND PMEMD_F_DEFINITIONS PUBFFT)
endif()

