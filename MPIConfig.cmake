#CMake config file for MPI
# MUST be included after OpenMPConfig, if OpenMPConfig is included at all
option(MPI "Build ${PROJECT_NAME} with MPI inter-machine parallelization support." FALSE)

include(ParallelizationConfig)

if(MPI)
	find_package(MPI)
	
	foreach(LANG C CXX Fortran)
		if(NOT MPI_${LANG}_FOUND)
			message(FATAL_ERROR "You requested MPI, but the MPI ${LANG} library as not found.  \
Please install one and try again, or set MPI_${LANG}_INCLUDE_PATH and MPI_${LANG}_LIBRARIES to point to your MPI.")
		endif()
	
		if(FIRST_RUN)
			message(STATUS "MPI ${LANG} Compiler: ${MPI_${LANG}_COMPILER}")
		endif()
	endforeach()
	
	if(FIRST_RUN)	
		message("If these are not the correct MPI wrappers, then set MPI_<language>_COMPILER to the correct wrapper and reconfigure.")
	endif()
	
	#Trim leading spaces from the compile flags.  They cause problems with PROPERTY COMPILE_OPTIONS
	foreach(LANG C CXX Fortran)
		
		# this shadows the cache variable with a local variable	
		string(STRIP "${MPI_${LANG}_COMPILE_FLAGS}" MPI_${LANG}_COMPILE_FLAGS)
		
	endforeach()
	
	# add MPI to the library tracker
	# combine all languages' MPI libraries
	set(ALL_MPI_LIBRARIES ${MPI_C_LIBRARIES} ${MPI_CXX_LIBRARIES} ${MPI_Fortran_LIBRARIES})
		
	list(REMOVE_DUPLICATES ALL_MPI_LIBRARIES)
	
	foreach(LIB ${ALL_MPI_LIBRARIES})
		using_external_library(${LIB})
	endforeach()
	
	# the MinGW port-hack of MS-MPI needs to be compiled with -fno-range-check
	if("${MPI_Fortran_LIBRARIES}" MATCHES "msmpi" AND ${CMAKE_Fortran_COMPILER_ID} STREQUAL GNU)
		message(STATUS "MS-MPI range check workaround active")
		
		#create a non-cached variable with the contents of the cache variable plus one extra flag
		set(MPI_Fortran_COMPILE_FLAGS ${MPI_Fortran_COMPILE_FLAGS} -fno-range-check)
	endif()
	
	message("MPI_C_COMPILE_FLAGS: ${MPI_C_COMPILE_FLAGS}")
	
	# create imported targets
	# --------------------------------------------------------------------
	foreach(LANG C CXX Fortran)
		string(TOLOWER ${LANG} LANG_LOWERCASE)
		import_libraries(mpi_${LANG_LOWERCASE} LIBRARIES ${MPI_${LANG}_LINK_FLAGS} ${MPI_${LANG}_LIBRARIES} INCLUDES ${MPI_${LANG}_INCLUDE_PATH})
		set_property(TARGET mpi_${LANG_LOWERCASE} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${MPI_${LANG}_INCLUDE_PATH})
		
		if(MCPAR_WORKAROUND_ENABLED)
			# use generator expression
			set_property(TARGET mpi_${LANG_LOWERCASE} PROPERTY INTERFACE_COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:${LANG}>:${MPI_${LANG}_COMPILE_FLAGS}>)
		else()
			set_property(TARGET mpi_${LANG_LOWERCASE} PROPERTY INTERFACE_COMPILE_OPTIONS ${MPI_${LANG}_COMPILE_FLAGS})
		endif()
		
		# C++ MPI doesn't like having "MPI" defined, but it's what Amber uses as the MPI switch in most programs (though not EMIL)
		if(NOT ${LANG} STREQUAL CXX)
			set_property(TARGET mpi_${LANG_LOWERCASE} PROPERTY INTERFACE_COMPILE_DEFINITIONS MPI)	
		endif()
			
	endforeach()
	
	
	# Add MPI support to an object library
	macro(mpi_object_library TARGET LANGUAGE)
		target_compile_options(${TARGET} PRIVATE ${MPI_${LANG}_COMPILE_FLAGS})
		target_compile_definitions(${TARGET} PUBLIC ${MPI_${LANG}_INCLUDE_PATH})
	endmacro()

	# make a version of the thing passed 
	# also allows switching out sources if needed
	# usage: make_mpi_version(<target> <new name> LANGUAGES <language 1> [<language 2...>] [SWAP_SOURCES <source 1...> TO <replacement source 1...>])
	function(make_mpi_version TARGET NEW_NAME) 
	
		# parse arguments
		# --------------------------------------------------------------------	
		cmake_parse_arguments(MAKE_MPI "" "" "LANGUAGES;SWAP_SOURCES;TO" ${ARGN})
	
		if("${MAKE_MPI_LANGUAGES}" STREQUAL "")
			message(FATAL_ERROR "Incorrect usage.  At least one LANGUAGE should be provided.")
		endif()
		
		# make sure that both SWAP_SOURCES and TO are provided if either is
		if(("${MAKE_MPI_SWAP_SOURCES}" STREQUAL "" AND NOT "${MAKE_MPI_TO}" STREQUAL "") OR ((NOT "${MAKE_MPI_SWAP_SOURCES}" STREQUAL "") AND "${MAKE_MPI_TO}" STREQUAL ""))
			message(FATAL_ERROR "Incorrect usage.  You must provide both SWAP_SOURCES and TO, or neither at all.")
		endif()
		
		
		if(NOT "${IMP_LIBS_UNPARSED_ARGUMENTS}" STREQUAL "")
			message(FATAL_ERROR "Incorrect usage.  Extra arguments provided.")
		endif()
	
		
		# figure out if it's an object library, and if so, use mpi_object_library()		
		get_property(TARGET_TYPE TARGET ${TARGET} PROPERTY TYPE)
		
		if("${TARGET_TYPE}" STREQUAL "OBJECT_LIBRARY")
			set(IS_OBJECT_LIBRARY TRUE)
		else()
			set(IS_OBJECT_LIBRARY FALSE)
		endif()
		
		if("${ARGN}" STREQUAL "")
			message(FATAL_ERROR "make_mpi_version(): you must specify at least one LANGUAGE") 
		endif()
		
		# make a new one
		# --------------------------------------------------------------------
		if("${MAKE_MPI_SWAP_SOURCES}" STREQUAL "")
			message("copy_target(${TARGET} ${NEW_NAME})") 
			copy_target(${TARGET} ${NEW_NAME})
		else()
			copy_target(${TARGET} ${NEW_NAME} SWAP_SOURCES ${MAKE_MPI_SWAP_SOURCES} TO ${MAKE_MPI_TO})
		endif()
		
		# apply MPI flags
		# --------------------------------------------------------------------
		foreach(LANG ${MAKE_MPI_LANGUAGES})
			# validate arguments
			if(NOT ("${LANG}" STREQUAL "C" OR "${LANG}" STREQUAL "CXX" OR "${LANG}" STREQUAL "Fortran"))
				message(FATAL_ERROR "make_mpi_version(): invalid argument: ${LANG} is not a LANGUAGE")
			endif()
			
			if(IS_OBJECT_LIBRARY)
				mpi_object_library(${NEW_NAME} ${LANG})
			else()
				string(TOLOWER ${LANG} LANG_LOWERCASE)
				target_link_libraries(${NEW_NAME} mpi_${LANG_LOWERCASE})
			endif()
			
		endforeach()
	endfunction(make_mpi_version)
endif()

