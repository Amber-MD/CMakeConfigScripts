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

include(GetPrerequisites)
include(${CMAKE_CURRENT_LIST_DIR}/Shorthand.cmake)

message("Bundling OSX dependencies for package rooted at: ${PACKAGE_PREFIX}")

file(GLOB PACKAGE_LIBRARIES LIST_DIRECTORIES FALSE "${PACKAGE_PREFIX}/lib/*${CMAKE_SHARED_LIBRARY_SUFFIX}")
file(GLOB PACKAGE_EXECUTABLES LIST_DIRECTORIES FALSE "${PACKAGE_PREFIX}/bin/*${CMAKE_EXECUTABLE_SUFFIX}")

# items are taken from, and added to, this stack.
# All files in this list are already in the installation prefix
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
				
				list(APPEND COPIED_EXTERNAL_DEPENDENCIES ${PREREQUISITE_LIB})
				list(APPEND COPIED_EXTERNAL_DEPS_NEW_PATHS ${NEW_PREREQ_PATH})
				list(APPEND ITEMS_TO_PROCESS ${NEW_PREREQ_PATH})
			endif()
		endif()

	endforeach()
	
	list(REMOVE_AT ITEMS_TO_PROCESS 0)
	list(APPEND PROCESSED_ITEMS_BY_NEW_PATH ${CURRENT_ITEM})
	
endwhile()

message("Dependency bundling done!")