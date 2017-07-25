#Modified version of BISON_TARGET (from FindBison) which uses AMBER's in-tree byacc
#some yacc programs in AMBER use syntax that won't compile with GNU bison, so we have to use byacc.  Believe me, I've tried.

#usage: byacc_target(<target name> <input file> <output directory> [GENERATE_HEADER] [COMPILE_FLAGS <flags...>] [FILE_PREFIX <prefix (default 'y')>])
#always generates the ${FILE_PREFIX}.tab.c (and possibly ${FILE_PREFIX}.tab.h) in the output directory
#input file is relative to the current source directory

#GENERATE_HEADER: also generate ${FILE_PREFIX}.tab.h

#Targets created by this macro work with add_flex_bison_dependency()

macro(byacc_target NAME INPUT OUTPUT_DIR)
	set(BYACC_TARGET_output_header "")
	set(BYACC_TARGET_cmdopt "")
	
	cmake_parse_arguments(
		BYACC_TARGET_ARG
		GENERATE_HEADER
	 	FILE_PREFIX
		COMPILE_FLAGS
		${ARGN})

	if(NOT "${BYACC_TARGET_ARG_UNPARSED_ARGUMENTS}" STREQUAL "")
	  message(SEND_ERROR "Incorrect Usage")
	else()
		
		if(NOT "${BYACC_TARGET_ARG_COMPILE_FLAGS}" STREQUAL "")
			list(APPEND BYACC_TARGET_cmdopt ${BYACC_TARGET_ARG_COMPILE_FLAGS})
		endif()
		
		if("${BYACC_TARGET_ARG_FILE_PREFIX}" STREQUAL "")
			set(BYACC_TARGET_ARG_FILE_PREFIX y) 
		else()
			list(APPEND BYACC_TARGET_cmdopt -b ${BYACC_TARGET_ARG_FILE_PREFIX})
		endif()
		
		set(BYACC_TARGET_outputs ${OUTPUT_DIR}/${BYACC_TARGET_ARG_FILE_PREFIX}.tab.c)
		
		if(${BYACC_TARGET_ARG_GENERATE_HEADER})
			list(APPEND BYACC_TARGET_cmdopt -d)
			list(APPEND BYACC_TARGET_outputs ${OUTPUT_DIR}/${BYACC_TARGET_ARG_FILE_PREFIX}.tab.h)
		endif()
			
		add_custom_command(OUTPUT ${BYACC_TARGET_outputs}
			COMMAND ${RUNNABLE_byacc} ${BYACC_TARGET_cmdopt} ${CMAKE_CURRENT_SOURCE_DIR}/${INPUT}
			VERBATIM
			DEPENDS ${INPUT}
			COMMENT "[BYACC][${NAME}] Building parser with berkeley yacc"
			WORKING_DIRECTORY ${OUTPUT_DIR})

	  # define target variables
	  # use "BISON" for compatibility with bison_target
	  set(BISON_${NAME}_DEFINED TRUE)
	  set(BISON_${NAME}_INPUT ${INPUT})
	  set(BISON_${NAME}_OUTPUTS ${BYACC_TARGET_outputs})
	  set(BISON_${NAME}_COMPILE_FLAGS ${BYACC_TARGET_cmdopt})
	  set(BISON_${NAME}_OUTPUT_SOURCE ${OUTPUT_DIR}/${BYACC_TARGET_ARG_FILE_PREFIX}.tab.c)
	  set(BISON_${NAME}_OUTPUT_HEADER ${OUTPUT_DIR}/${BYACC_TARGET_ARG_FILE_PREFIX}.tab.h)

	endif()
endmacro()
