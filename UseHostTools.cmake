# File that handles using an installation of Amber Host Tools to compile Amber
# This also sets the RUNNABLE_<program> variables for the rest of the build system to the versions of each program that can be run on the build system.

set(EXECUTABLES_TO_IMPORT byacc ucpp utilMakeHelp nab2c rule_parse)

if(USE_HOST_TOOLS)
	
	if(NOT EXISTS ${HOST_TOOLS_DIR}) 
		message(FATAL_ERROR "Provided Amber Host Tools directory does not exist.  Please set HOST_TOOLS_DIR to a valid host tools directory to use host tools")
	endif()
	
	
	#import executables as "host_" versions
	foreach(EXECUTABLE ${EXECUTABLES_TO_IMPORT})
	
		# we do not know the __host__ executable suffix, so we have to do a file search to figure out the last part of the filename
		file(GLOB EXECUTABLE_PATH_POSSIBILITIES "${HOST_TOOLS_DIR}/bin/${EXECUTABLE}*")
		list(LENGTH EXECUTABLE_PATH_POSSIBILITIES NUM_POSSIBILITIES)
		if(${NUM_POSSIBILITIES} GREATER 1)
			message(FATAL_ERROR "Multiple candidates for executable ${EXECUTABLE} in directory ${HOST_TOOLS_DIR}/bin")
		elseif(${NUM_POSSIBILITIES} EQUAL 0)
			message(FATAL_ERROR "Provided Amber Host Tools directory (${HOST_TOOLS_DIR}) is missing the executable ${EXECUTABLE}")
		else()
			set(EXECUTABLE_PATH ${EXECUTABLE_PATH_POSSIBILITIES})
		endif()
				
		add_executable(${EXECUTABLE}_host IMPORTED)
		set_property(TARGET ${EXECUTABLE}_host PROPERTY IMPORTED_LOCATION ${EXECUTABLE_PATH})
		
		#the runnable versions are the host tools versions
		set(RUNNABLE_${EXECUTABLE} ${EXECUTABLE}_host)
	endforeach()
else()
	#the runnable versions are the built versions
	foreach(EXECUTABLE ${EXECUTABLES_TO_IMPORT})
		set(RUNNABLE_${EXECUTABLE} ${EXECUTABLE})
	endforeach()
endif()