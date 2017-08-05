#CMake config file for MPI
# MUST be included after OpenMPConfig, if OpenMPConfig is included at all
option(MPI "Build Amber with MPI inter-machine parallelization support." FALSE)

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
else()
	#set these flags to empty string so that they can be used all the time without having to worry about wihether MPI is enabled
	foreach(LANG C CXX Fortran)
		set(MPI_${LANG}_COMPILE_FLAGS "")
		set(MPI_${LANG}_INCLUDE_PATH "")
	endforeach()
endif()


#Link MPI to a target.  Does nothing if MPI is disabled.
#the LANGUAGE arg is the language of the compiler used to link the target, ususally the language making up the largest percentage of source files.
#This macro will set that to be the used linker language, so you'll find out if you guessed wrong!

#NOTE: this will not overwrite the LINK_FLAGS property of the target.  Make sure nothing else does!
macro(link_mpi TARGET LANGUAGE)
	if(MPI)	
		#link the MPI libraries
		target_link_libraries(${TARGET} ${MPI_${LANGUAGE}_LIBRARIES})
		
		#Append the MPI link flags
		get_property(CURRENT_LINK_FLAGS TARGET ${TARGET} PROPERTY LINK_FLAGS)
				
		set(NEW_LINK_FLAGS "${CURRENT_LINK_FLAGS} ${MPI_${LANGUAGE}_LINK_FLAGS}")		
		set_property(TARGET ${TARGET} PROPERTY LINK_FLAGS ${NEW_LINK_FLAGS})
				
		#force the linker language
		set_property(TARGET ${TARGET} PROPERTY LINKER_LANGUAGE ${LANGUAGE})
	endif()
endmacro()

if(DEFINED OPENMP AND (OPENMP OR MPI))
	set(PARALLEL TRUE)
else()
	set(PARALLEL FALSE)
endif()