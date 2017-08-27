#Cmake config file for OpenMP
option(OPENMP "Use OpenMP for shared-memory parallelization." FALSE)

include(ParallelizationConfig)

if(OPENMP)
	if(DRAGONEGG)
		message(FATAL_ERROR "OpenMP is not compatible with Dragonegg.  Disable one or the other to build.")
	endif()
	
	find_package(OpenMPFixed)
	
	# check that for each language, either OpenMP was found, or the language is disabled.
	foreach(LANG C CXX Fortran)
		if(NOT ("${CMAKE_${LANG}_COMPILER_ID}" STREQUAL "" OR OpenMP_${LANG}_FOUND))
			message(FATAL_ERROR "You requested OpenMP support, but your ${LANG} compiler doesn't seem to support OpenMP.  Please set OPENMP to FALSE, or switch to a compiler that supports it.")
		endif()
	endforeach()
	
	foreach(LANG C CXX FORTRAN)
		# add libraries to library tracker
		using_external_libraries(${OpenMP_${LANG}_LIBRARIES})
	endforeach()
	
endif()

