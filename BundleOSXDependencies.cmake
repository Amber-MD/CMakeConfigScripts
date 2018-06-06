# Script run at install-time to:
# * locate dependencies of executables and libraries
# * copy them to the install directory
# * fix the install_name of the depender to point to the dependency on the RPATH
# * add a new RPATH entry on the dependency for its new location and remove its old install name
# * repeat above for dependencies of the dependency, and all other dependencies

# arguments:
# PACKAGE_PREFIX -- root of a UNIX-structure package to operate on
# CMAKE_SHARED_LIBRARY_SUFFIX -- pass this variable in from your CMake script
# CMAKE_EXECUTABLE_SUFFIX -- pass this variable in from your CMake script

# notes:
# * assumes that ${PACKAGE_PREFIX}/lib is, and should be, the rpath for all internal and external libraries
# * does not handle @executable_path since Amber doesn't use it; only handles @rpath and @loader_path

# This script was inspired by Hai Nguyen's similar script at https://github.com/Amber-MD/ambertools-binary-build/blob/master/conda_tools/update_gfortran_libs_osx.py

# Returns true iff the given dependency library should be ignored and not copied to the prefix
function(should_ignore_dep_library LIB_PATH OUTPUT_VARIABLE)
	if("${LIB_PATH}" MATCHES ".framework")
		set(${OUTPUT_VARIABLE} 1 PARENT_SCOPE)
	elseif("${LIB_PATH}" MATCHES "libSystem.B")
		set(${OUTPUT_VARIABLE} 1 PARENT_SCOPE)
	else()
		set(${OUTPUT_VARIABLE} 0 PARENT_SCOPE)
	endif()
endfunction(should_ignore_dep_library)

# Makes sure that the library named by LIB_PATH has the given RPATH location
function(add_rpath LIB_PATH RPATH)

	message(">>>> Adding RPATH of \"${RPATH}\" to ${LIB_PATH}")

	execute_process(COMMAND install_name_tool
		-add_rpath ${RPATH} ${LIB_PATH}
		ERROR_VARIABLE INT_ERROR_OUTPUT
		RESULT_VARIABLE INT_RESULT_CODE)
	
	# uhhh, I really hope the user has their language set to English...	
	if("${INT_ERROR_OUTPUT}" MATCHES "would duplicate path")
		# do nothing, it already exists which is OK
	elseif(NOT ${INT_RESULT_CODE} EQUAL 0)
		message("!! Failed to execute install_name_tool! Error message was: ${INT_ERROR_OUTPUT}")
	endif()
	
endfunction(add_rpath)

# Sets the install name (the name that other libraries save at link time, and use at runtime to find the library) of the given library to INSTALL_NAME
function(set_install_name LIB_PATH INSTALL_NAME)

	message(">> Setting install name of ${LIB_PATH} to \"${INSTALL_NAME}\"")

	execute_process(COMMAND install_name_tool
		-id ${INSTALL_NAME} ${LIB_PATH}
		ERROR_VARIABLE INT_ERROR_OUTPUT
		RESULT_VARIABLE INT_RESULT_CODE)
	
	if(NOT ${INT_RESULT_CODE} EQUAL 0)
		message("!! Failed to execute install_name_tool! Error message was: ${INT_ERROR_OUTPUT}")
	endif()
	
endfunction(set_install_name)

include(GetPrerequisites)
include(${CMAKE_CURRENT_LIST_DIR}/Shorthand.cmake)

message("Bundling OSX dependencies for package rooted at: ${PACKAGE_PREFIX}")

file(GLOB PACKAGE_LIBRARIES LIST_DIRECTORIES FALSE "${PACKAGE_PREFIX}/lib/*${CMAKE_SHARED_LIBRARY_SUFFIX}")
file(GLOB PACKAGE_EXECUTABLES LIST_DIRECTORIES FALSE "${PACKAGE_PREFIX}/bin/*${CMAKE_EXECUTABLE_SUFFIX}")

# items are taken from, and added to, this stack.
# All files in this list are already in the installation prefix, and already have correct RPATHs
set(ITEMS_TO_PROCESS ${PACKAGE_LIBRARIES} ${PACKAGE_EXECUTABLES})


# lists of completed items (can skip if we see a dependency on these)
# This always contains the path inside the prefix
set(PROCESSED_ITEMS_BY_NEW_PATH "")

# List of external libraries which have already been copied to the prefix (by their external paths)
set(COPIED_EXTERNAL_DEPENDENCIES "")

# List that matches each index in the above list with the new path of the library
set(COPIED_EXTERNAL_DEPS_NEW_PATHS "")

while(1)

	list(LENGTH ITEMS_TO_PROCESS NUM_ITEMS_LEFT)
		
	if(${NUM_ITEMS_LEFT} EQUAL 0)
		break()
	endif()
	
	list(GET ITEMS_TO_PROCESS 0 CURRENT_ITEM)
	
	message("Considering ${CURRENT_ITEM}")
	
	set(CURRENT_ITEM_PREREQUISITES "")
	get_prerequisites(${CURRENT_ITEM} CURRENT_ITEM_PREREQUISITES 0 0 "" ${PACKAGE_PREFIX}/lib ${PACKAGE_PREFIX}/lib)
	
	foreach(PREREQUISITE_LIB ${CURRENT_ITEM_PREREQUISITES})
		
		# resolve RPATH references
		string(REPLACE "@rpath" "${PACKAGE_PREFIX}/lib" PREREQUISITE_LIB "${PREREQUISITE_LIB}")
		
		if(NOT EXISTS "${PREREQUISITE_LIB}")
			message("!! Unable to resolve library dependency ${PREREQUISITE_LIB} -- skipping")
			break()
		endif()
		

		should_ignore_dep_library(${PREREQUISITE_LIB} SHOULD_IGNORE_PREQUISITE)
		
		if(SHOULD_IGNORE_PREQUISITE)
			message(">> Ignoring dependency: ${PREREQUISITE_LIB}")
		else()
			# check if we already know about this library, and copy it here if we don't
			list(FIND COPIED_EXTERNAL_DEPENDENCIES "${PREREQUISITE_LIB}" INDEX_IN_COPIED_DEPS)
			list(FIND PACKAGE_LIBRARIES "${PREREQUISITE_LIB}" INDEX_IN_PACKAGE_LIBRARIES)
			
			if(NOT INDEX_IN_COPIED_DEPS EQUAL -1)
				message(">> Already copied dependency: ${PREREQUISITE_LIB}")
			elseif(NOT INDEX_IN_PACKAGE_LIBRARIES EQUAL -1)
				message(">> Dependency is internal: ${PREREQUISITE_LIB}")
			else()
				# previously unseen library -- copy to the prefix and queue for processing
				message(">> Copy library dependency: ${PREREQUISITE_LIB}")
				
				# resolve symlinks
				get_filename_component(PREREQ_LIB_REALPATH ${PREREQUISITE_LIB} REALPATH)
				file(COPY "${PREREQ_LIB_REALPATH}" DESTINATION ${PACKAGE_PREFIX}/lib FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ WORLD_READ)
				
				# find new filename
				get_filename_component(PREREQ_LIB_FILENAME "${PREREQ_LIB_REALPATH}" NAME)
				set(NEW_PREREQ_PATH "${PACKAGE_PREFIX}/lib/${PREREQ_LIB_FILENAME}")
				
				# add correct RPATH
				add_rpath(${NEW_PREREQ_PATH} "@loader_path/../${LIBDIR}")
				
				list(APPEND COPIED_EXTERNAL_DEPENDENCIES ${PREREQUISITE_LIB})
				list(APPEND COPIED_EXTERNAL_DEPS_NEW_PATHS ${NEW_PREREQ_PATH})
				list(APPEND ITEMS_TO_PROCESS ${NEW_PREREQ_PATH})
			endif()
		endif()

	endforeach()
	
	if("${CURRENT_ITEM}" MATCHES "${CMAKE_SHARED_LIBRARY_SUFFIX}$")
	
		# if it's a library, set its install name to refer to it on the RPATH (so anything can link to it as long as it uses the $AMBERHOME/lib RPATH)
		get_filename_component(CURRENT_ITEM_FILENAME "${CURRENT_ITEM}" NAME)
		set_install_name(${CURRENT_ITEM} "@rpath/${CURRENT_ITEM_FILENAME}")
		
	endif()
	
	list(REMOVE_AT ITEMS_TO_PROCESS 0)
	list(APPEND PROCESSED_ITEMS_BY_NEW_PATH ${CURRENT_ITEM})
	
endwhile()

message("Dependency bundling done!")