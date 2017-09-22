#Macro which invokes nab2c and compiles .nab files into .c files

# It is used instead of the nab wrapper program because
# the nab wrapper is hardcoded to use the installed directory structure, and would need significant changes to work with the CMake structure

# It's also just kind of nice to build the c files in CMake instead of through NAB

# the directory where the nab headers are in the source tree
set(NAB_HEADER_DIR ${CMAKE_SOURCE_DIR}/AmberTools/src/nab)

#compiles NAB_FILES into GENERATED_C_FILES
#add GENERATED_C_FILES as source code to a target
macro(nab_compile GENERATED_C_FILES) #2nd argument: NAB_FILES...
	
	#create the intermediates dir if it doesn't exist
	set(C_FILES_DIR "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/nabfiles")
	file(MAKE_DIRECTORY ${C_FILES_DIR})
	
	#turn include directories into preprocessor arguments
	if(DEFINED NAB_INCLUDE_DIRS)
		foreach(INCDIR ${NAB_INCLUDE_DIRS})
			list(APPEND CPP_ARGS "-I${INCDIR}")
		endforeach()
    endif()
    
    list(APPEND CPP_ARGS "-I${NAB_HEADER_DIR}")
    
	if(DEFINED NAB_DEFINITIONS)
		foreach(DEFINITION ${NAB_DEFINITIONS})
			list(APPEND CPP_ARGS "-D${DEFINITION}")
		endforeach()
	endif()

	#set up build rules for each nab file
	foreach(NAB_FILE ${ARGN})
		get_filename_component(NAB_FILENAME ${NAB_FILE} NAME)
			
		strip_last_extension(NAB_FILE_BASENAME ${NAB_FILENAME})	
		#we use .i because it is the extension GCC uses for preprocessed intermediates
		set(PREPROCESSED_INTERMEDIATE ${C_FILES_DIR}/${NAB_FILENAME}.i)
	
		set(GENERATED_C_FILE ${C_FILES_DIR}/${NAB_FILE_BASENAME}.c)
				
		add_custom_command(OUTPUT ${PREPROCESSED_INTERMEDIATE}
			COMMAND ${RUNNABLE_ucpp} ${CPP_ARGS} -l -o ${PREPROCESSED_INTERMEDIATE} "${CMAKE_CURRENT_SOURCE_DIR}/${NAB_FILE}"
			VERBATIM
			DEPENDS ${NAB_FILE}
			IMPLICIT_DEPENDS C ${NAB_FILE} #try to scan #include dependencies of nab file
			COMMENT "[NAB] Preprocessing ${NAB_FILENAME}"
			WORKING_DIRECTORY ${C_FILES_DIR})
		
		add_custom_command(OUTPUT ${GENERATED_C_FILE}
			COMMAND ${RUNNABLE_nab2c} -nfname ${NAB_FILENAME} < ${PREPROCESSED_INTERMEDIATE}
			VERBATIM
			DEPENDS ${PREPROCESSED_INTERMEDIATE} nab2c
			COMMENT "[NAB] Compiling ${NAB_FILENAME}"
			WORKING_DIRECTORY ${C_FILES_DIR})
		list(APPEND ${GENERATED_C_FILES} ${GENERATED_C_FILE})	
	endforeach()
		
endmacro()

#function which condenses the four lines of boilerplate to create a nab executable into one line.
#you pass it an executable target name, a list of nab sources, and a list of C sources, and it will create the
#executable and set up the nab sources to be compiled.

#The targets it creates are regular executable targets, so they can be linked to and installed

#usage: add_nab_executable(<target name> NAB_SOURCES <nab sources...> [C_SOURCES <c sources...>])
function(add_nab_executable EXE_NAME)

	#parse the arguents
    cmake_parse_arguments(
        ADD_NABEXE
        ""
        ""
        "NAB_SOURCES;C_SOURCES"
        ${ARGN})
	
	if(${ADD_NABEXE_NAB_SOURCES} STREQUAL "")
		message(SEND_ERROR "Incorrect arguments: No nab sources provided.")
	endif()
	
	if(NOT ${ADD_NABEXE_UNPARSED_ARGUMENTS} STREQUAL "")
		message(SEND_ERROR "Usage error: Unknown arguments provided.")
	endif()
	
	#create the executable
    nab_compile(${EXE_NAME}_COMPILED_NAB ${ADD_NABEXE_NAB_SOURCES})
    add_executable(${EXE_NAME} ${${EXE_NAME}_COMPILED_NAB} ${ADD_NABEXE_C_SOURCES})
    target_link_libraries(${EXE_NAME} libnab)    
    
endfunction(add_nab_executable)