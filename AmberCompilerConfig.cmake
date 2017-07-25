#This file sets the (cross) compiler based on the COMPILER and TARGET variables

#create COMPILER option
set(COMPILER "auto" CACHE STRING "Compiler to build Amber with.  Valid values: gnu, intel, pgi, cray, clang, auto.  If 'auto', autodetect the host compiler, or use the CC,CXX,and FC variables if they are set.
 This option can ONLY be set the first time CMake is run.  If you want to change it, delete the build directory and start over.")

option(CROSSCOMPILE "Whether to crosscompile.  If true, assume that executables built by the compiler cannot run on the build system.") 

#cmake must have the absolute path to the compiler when setting it from a script (despite an error message to the contrary), so we make this helper function
macro(set_compiler LANGUAGE COMP_NAME)
	get_filename_component(${COMP_NAME}_LOCATION ${COMP_NAME} PROGRAM)
		
	if(NOT EXISTS "${${COMP_NAME}_LOCATION}") #we use EXISTS here to check that we have a full path
		message(FATAL_ERROR "Could not find ${LANGUAGE} compiler executable ${COMP_NAME}.  Is it installed?")
	endif()
	
	message(STATUS "Setting ${LANGUAGE} compiler to ${COMP_NAME}")
	set(CMAKE_${LANGUAGE}_COMPILER ${${COMP_NAME}_LOCATION})
endmacro(set_compiler)

#configure crosscompiling
if(CROSSCOMPILE)
	# host tools are required to cross compile.
	if(NOT USE_HOST_TOOLS)
		message(FATAL_ERROR "You must build and provide Amber Host Tools before you can crosscompile.  First build Amber using BUILD_HOST_TOOLS=TRUE, and install it to a location separate from your regular install prefix.  Then, turn off BUILD_HOST_TOOLS, enable USE_HOST_TOOLS, enable cross-compilation, and set HOST_TOOLS_DIR to point to where you installed the host tools.")
	endif()
	
	#check if the compiler can crosscompile
	list_contains(CAN_CROSSCOMPILE ${COMPILER} gnu clang)
	if(NOT CAN_CROSSCOMPILE)
		message(FATAL_ERROR "Cannot crosscompile with compiler ${COMPILER}.  Please explicitly set COMPILER to either gnu or clang.")
	endif()
	
	if("${CMAKE_SYSTEM_NAME}" STREQUAL "")
		message(FATAL_ERROR "You must set CMAKE_SYSTEM_NAME to cross-compile.  Common values are Linux, Darwin, and Windows")
	endif()
	
	message(STATUS "Crosscompiling for ${CMAKE_SYSTEM_NAME}")
	set(CMAKE_CROSSCOMPILING TRUE)
	
	if("${TARGET_TRIPLE}" STREQUAL "" OR "${CMAKE_FIND_ROOT_PATH}" STREQUAL "")
		message(FATAL_ERROR "CMAKE_FIND_ROOT_PATH and TARGET_TRIPLE must be set when crosscompiling. Read the wiki for details.")
	endif()
		
	set(CMAKE_C_COMPILER_TARGET ${TARGET_TRIPLE})
	set(CMAKE_CXX_COMPILER_TARGET ${TARGET_TRIPLE})
		
	# adjust the default behaviour of the FIND_XXX() commands:
	# search headers and libraries in the target environment, search 
	# programs in the host environment
	set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
	set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
	set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
else()
	set(CROSSCOMPILE FALSE)
endif()

#-------------------------------------------------------------------------------
#  Set compiler executables
#-------------------------------------------------------------------------------
if(FIRST_RUN)
	
	if(${COMPILER} STREQUAL gnu)
		
		if(CROSSCOMPILE)
			set_compiler(C ${TARGET_TRIPLE}-gcc)
			set_compiler(CXX ${TARGET_TRIPLE}-g++)
			set_compiler(Fortran ${TARGET_TRIPLE}-gfortran)
			
			message("Using cross GCC: ${TARGET_TRIPLE}-gcc")
		else()
			set_compiler(C gcc)
			set_compiler(CXX "g++")
			set_compiler(Fortran gfortran)
			
		endif()
	elseif(${COMPILER} STREQUAL clang)
		set_compiler(C clang)
		set_compiler(CXX "clang++")
		
		#clang does not have a fortran compiler, so we use gfortran
		if(CROSSCOMPILE)
			set_compiler(Fortran ${TARGET_TRIPLE}-gfortran)
			message("Using cross Clang + gfortran: ${TARGET_TRIPLE}-clang")
		else()
			set_compiler(Fortran gfortran)
		endif()
	elseif(${COMPILER} STREQUAL intel)
		set_compiler(C icc)
		set_compiler(CXX icpc)
		set_compiler(Fortran ifort)
	elseif(${COMPILER} STREQUAL pgi)
		set_compiler(C pgcc)
		set_compiler(CXX pgc++)
		set_compiler(Fortran pgf90)
	elseif(${COMPILER} STREQUAL cray)
		#all that is needed is to tell CMake that it is not running on regular linux but in fact on a Cray node
		set(CMAKE_SYSTEM_NAME CrayLinuxEnvironment) 
	endif()
endif()	


