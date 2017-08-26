# Across the build system, we need to keep track of which libraries we are using, for two reasons:
# 1. Installers and packages need to bundle them or depend on them.
# 2. Nab needs to know which libraries to link to things it builds.

# Here, we create macros for recording which external libraries are used.

# on Windows:
# We package DLLs in the bin folder
# We package import and static libraries in the lib folder

# on everything else:
# We package/depend on libraries in the lib folder
 
# these must be cache variables so that they can be set from within a function
set(USED_LIB_RUNTIME_PATH "" CACHE INTERNAL "Paths to shared libraries needed at runtime" FORCE) # Path to a .so, .dylib, or .dll library.  "<none>" if the library is static only.
set(USED_LIB_LINKTIME_PATH "" CACHE INTERNAL "Paths to shared libraries needed at link time" FORCE) # Path to a .a or .lib static library, or an import library
set(USED_LIB_NAME "" CACHE INTERNAL "Names of used shared libraries" FORCE) # contains the library names as supplied to the linker.

# linker flag prefix -- if a link library starts with this character, it will be ignored by import_libraries()
# this is needed because FindMKL can return linker flags mixed with its libraries (which is actually the official CMake way of doing things)
if(TARGET_WINDOWS AND NOT MINGW)
	set(LINKER_FLAG_PREFIX "/")  # stupid illogical MSVC command-line format...
else()
	set(LINKER_FLAG_PREFIX "-")
endif()

# utility functions
# --------------------------------------------------------------------

#Unfortunately, CMake doesn't let you import a library without knowing whether it is shared or static, but there's no easy way to tell.
#sets OUTPUT_VARAIBLE to "IMPORT", "SHARED", or "STATIC" depending on the library passed
function(get_lib_type LIBRARY OUTPUT_VARIABLE)

	if(NOT EXISTS ${LIBRARY})
		message(FATAL_ERROR "get_lib_type(): library ${LIBRARY} does not exist!")
	endif()

	# This is frustratingly platform-specific logic, but we have to do it
	get_filename_component(LIB_NAME ${LIBRARY} NAME)
	
	# first, check for import libraries
	if(TARGET_WINDOWS)
		if(MINGW)
			# on MinGW, import libraries have a different file extension, so our job is easy.
			if(${LIB_NAME} MATCHES ".*${CMAKE_IMPORT_LIBRARY_SUFFIX}")
				set(${OUTPUT_VARIABLE} IMPORT PARENT_SCOPE)
				return()
			endif()
		else() # MSVC, Intel, or some other Windows compiler
			
			# we have to work a little harder, and use Dumpbin to check the library type.
			find_program(DUMPBIN dumpbin)
			
			if(NOT DUMPBIN)
				message(FATAL_ERROR "The Microsoft Dumpbin tool was not found.  It is needed to analyze libraries, so please set the DUMPBIN variable to point to it.")
			endif()
			
			execute_process(COMMAND ${DUMPBIN} OUTPUT_VARIABLE DUMPBIN_OUTPUT ERROR_VARIABLE DUMPBIN_ERROUT RESULT_VARIABLE DUMPBIN_RESULT)
			
			# sanity check
			if(NOT ${DUMPBIN_RESULT} EQUAL 0)
				message(FATAL_ERROR "Could not analyze the type of library ${LIBRARY}: dumpbin failed to execute with error ${DUMPBIN_ERROUT}")
			endif()
			
			# check for dynamic symbol entries
			# https://stackoverflow.com/questions/488809/tools-for-inspecting-lib-files
			if("${DUMPBIN_OUTPUT}" MATCHES "Symbol name  :")
				# found one!  It's an import library!
				set(${OUTPUT_VARIABLE} IMPORT PARENT_SCOPE)
				return()
			endif()
		endif()
	endif()
	
	# now we can figure the rest out by suffix matching
	
	if(${LIB_NAME} MATCHES ".*${CMAKE_SHARED_LIBRARY_SUFFIX}")
		set(${OUTPUT_VARIABLE} SHARED PARENT_SCOPE)
	elseif(${LIB_NAME} MATCHES ".*${CMAKE_STATIC_LIBRARY_SUFFIX}")
		set(${OUTPUT_VARIABLE} STATIC PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Could not determine whether \"${LIBRARY}\" is a static or shared library, it does not have a known suffix.")
	endif()
endfunction(get_lib_type)

# Like using_external_library, but accepts multiple paths.
macro(using_external_libraries)	
	foreach(LIBRARY_PATH ${ARGN})
		using_external_library(${LIBRARY_PATH})
	endforeach()
endmacro(using_external_libraries)


# Notify the packager that an external library is being used
# If a Windows import library as passed as an argument, will automatically find and add the corresponding DLL
function(using_external_library LIBPATH)
	
	if("${LIBPATH}" STREQUAL "" OR NOT EXISTS "${LIBPATH}")
		message(FATAL_ERROR "Non-existant library ${LIBPATH} recorded as a used library")
	endif()
	
	if(NOT ("${USED_LIB_RUNTIME_PATH}" MATCHES "${LIBPATH}" OR "${USED_LIB_LINKTIME_PATH}" MATCHES "${LIBPATH}"))
		get_lib_type("${LIBPATH}" LIB_TYPE)

		# Figure out the library name that you'd feed to the linker from the filename
		# --------------------------------------------------------------------
	
		# get full library name
		get_filename_component(LIBNAME ${LIBPATH} NAME)
	
		#remove prefix
		string(REGEX REPLACE "^lib" "" LIBNAME ${LIBNAME})
	
		#remove numbers after the file extension
		string(REGEX REPLACE "(\\.[0-9])+$" "" LIBNAME ${LIBNAME})
		
		#remove the file extension
	
		if("${LIB_TYPE}" STREQUAL IMPORT)
			string(REGEX REPLACE "${CMAKE_IMPORT_LIBRARY_SUFFIX}$" "" LIBNAME ${LIBNAME})
		elseif("${LIB_TYPE}" STREQUAL STATIC)
			string(REGEX REPLACE "${CMAKE_STATIC_LIBRARY_SUFFIX}\$" "" LIBNAME ${LIBNAME})
		else()
			string(REGEX REPLACE "${CMAKE_SHARED_LIBRARY_SUFFIX}\$" "" LIBNAME ${LIBNAME})
		endif()
	
	
		# if we are on Windows, we need to find the corresponding .dll library if we got an import library
		# --------------------------------------------------------------------
	
		if("${LIB_TYPE}" STREQUAL IMPORT)
			# accept user override
			if(NOT DEFINED DLL_LOCATION_${LIBNAME})
				#try to find it in the bin subdirectory of the location where the import library is installed.
				get_filename_component(LIB_FOLDER ${LIBPATH} PATH)
				get_filename_component(POSSIBLE_DLL_FOLDER ${LIB_FOLDER}/../bin REALPATH)
			
				# DLLs often have a hyphen then a number as their suffix, so we use a fuzzy match, with and without the lib prefix.
				file(GLOB DLL_LOCATION_${LIBNAME} "${POSSIBLE_DLL_FOLDER}/${LIBNAME}*.dll")
			
				if("${DLL_LOCATION_${LIBNAME}}" STREQUAL "")
					file(GLOB DLL_LOCATION_${LIBNAME} "${POSSIBLE_DLL_FOLDER}/lib${LIBNAME}*.dll")
				endif()
			
				if("${DLL_LOCATION_${LIBNAME}}" STREQUAL "")
					message(WARNING "Could not locate dll file corresponding to the import library ${LIBPATH}. Please set DLL_LOCATION_${LIBNAME} to the correct DLL file.")
				endif()
			
				list(LENGTH DLL_LOCATION_${LIBNAME} NUM_POSSIBLE_PATHS)
				if(${NUM_POSSIBLE_PATHS} GREATER 1)
					message(WARNING "Found multiple dll files corresponding to the import library ${LIBPATH}. Please set DLL_LOCATION_${LIBNAME} to the correct DLL file.")
				endif()
			endif()
		endif()
	
		# save the data to the global lists
		# --------------------------------------------------------------------
	
		if("${LIB_TYPE}" STREQUAL IMPORT)
			set(USED_LIB_LINKTIME_PATH ${USED_LIB_LINKTIME_PATH} ${LIBPATH} CACHE INTERNAL "" FORCE)
			set(USED_LIB_RUNTIME_PATH ${USED_LIB_RUNTIME_PATH} ${DLL_LOCATION_${LIBNAME}} CACHE INTERNAL "" FORCE)
		
			message("Recorded DLL/implib combo ${LIBNAME}: import library at ${LIBPATH}, DLL at ${DLL_LOCATION_${LIBNAME}}")
		
		elseif("${LIB_TYPE}" STREQUAL STATIC)
			set(USED_LIB_LINKTIME_PATH ${USED_LIB_LINKTIME_PATH} ${LIBPATH} CACHE INTERNAL "" FORCE)
			set(USED_LIB_RUNTIME_PATH ${USED_LIB_RUNTIME_PATH} "<none>" CACHE INTERNAL "" FORCE)
		
			message("Recorded static library ${LIBNAME} at ${LIBPATH}")
		else() # Unix shared library
			set(USED_LIB_LINKTIME_PATH ${USED_LIB_LINKTIME_PATH} ${LIBPATH} CACHE INTERNAL "" FORCE)
			set(USED_LIB_RUNTIME_PATH ${USED_LIB_RUNTIME_PATH} ${LIBPATH} CACHE INTERNAL "" FORCE)
		
			message("Recorded shared library ${LIBNAME} at ${LIBPATH}")
		endif()
	
		set(USED_LIB_NAME ${USED_LIB_NAME} ${LIBNAME} CACHE INTERNAL "" FORCE)
	endif()
endfunction(using_external_library)


# import functions
# --------------------------------------------------------------------

# shorthand for adding an imported library, with a path and include dirs.

#usage: import_library(<library name> <library path> [include dir 1] [include dir 2]...)
function(import_library NAME PATH) #3rd arg: INCLUDE_DIRS

	#Try to figure out whether it is shared or static.
	get_lib_type(${PATH} LIB_TYPE)

	if("${LIB_TYPE}" STREQUAL STATIC)
		add_library(${NAME} STATIC IMPORTED GLOBAL)
	else()
		add_library(${NAME} SHARED IMPORTED GLOBAL)
	endif()

	set_property(TARGET ${NAME} PROPERTY IMPORTED_LOCATION ${PATH})
	set_property(TARGET ${NAME} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${ARGN})
	
	using_external_library("${PATH}")
	
endfunction(import_library)

# shorthand for adding one library target which corresponds to multiple linkable things
# "linkable things" can be any of 5 different types:
#    1. CMake imported targets (as created by import_library() or by another module)
#    2. File paths to libraries
#    3. CMake non-imported targets
#    4. Linker flags
#    5. Names of libraries to find on the linker path

# Things of the first 2 types are added to the library tracker.

#usage: import_libraries(<library name> LIBRARIES <library paths...> INCLUDES [include dir 1] [include dir 2]...)
function(import_libraries NAME)

	cmake_parse_arguments(IMP_LIBS "" "" "LIBRARIES;INCLUDES" ${ARGN})
	
	if("${IMP_LIBS_LIBRARIES}" STREQUAL "")
		message(FATAL_ERROR "Incorrect usage.  At least one LIBRARY should be provided.")
	endif()
	
	if(NOT "${IMP_LIBS_UNPARSED_ARGUMENTS}" STREQUAL "")
		message(FATAL_ERROR "Incorrect usage.  Extra arguments provided.")
	endif()
	
	# we actually don't use imported libraries at all; we just create an interface target and set its dependencies
	add_library(${NAME} INTERFACE)
	
	set_property(TARGET ${NAME} PROPERTY INTERFACE_LINK_LIBRARIES ${IMP_LIBS_LIBRARIES})
	set_property(TARGET ${NAME} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${IMP_LIBS_INCLUDES})
	
	# add to library tracker
	foreach(LIBRARY ${IMP_LIBS_LIBRARIES})
		if("${LIBRARY}" MATCHES "^${LINKER_FLAG_PREFIX}")
			# linker flag -- ignore
			
		elseif(EXISTS "${LIBRARY}")
			# full path to library
			using_external_library("${LIBRARY}")
			
		elseif(TARGET "${LIBRARY}")
			get_property(LIBRARY_HAS_IMPORTED_LOCATION TARGET ${LIBRARY} PROPERTY IMPORTED_LOCATION DEFINED)
			if(LIBRARY_HAS_IMPORTED_LOCATION)
				# CMake imported target
				get_property(LIBRARY_IMPORTED_LOCATION TARGET ${LIBRARY} PROPERTY IMPORTED_LOCATION)
				using_external_library("${LIBRARY_IMPORTED_LOCATION}")
				
			endif()
			# CMake target that is built by this project -- ignore
		endif()
		# otherwise it's a library name to find on the linker search path (using CMake in "naive mode")
	endforeach()
endfunction(import_libraries)
