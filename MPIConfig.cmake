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
	
	message("If these are not the correct MPI wrappers, then set MPI_<language>_COMPILER to the correct wrapper and reconfigure.")
	
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
	
endif()


# Build an object library with MPI support
macro(mpi_object_library TARGET LANGUAGE)
	target_compile_options(${TARGET} PRIVATE ${MPI_${LANG}_COMPILE_FLAGS})
	target_compile_definitions(${TARGET} PUBLIC ${MPI_${LANG}_INCLUDE_PATH})
endmacro()
