# Across the build system, we need to keep track of which libraries we are using, for two reasons:
# 1. Installers and packages need to bundle them or depend on them.
# 2. Nab needs to know which libraries to link to things it builds.

# Here, we create macros for recording which external libraries are used.

# on Windows:
# We package DLLs in the bin folder
# We package import and static libraries in the lib folder

# on everything else:
# We package/depend on libraries in the lib folder
 
 
set(USED_LIB_RUNTIME_PATH "") # Path to a .so, .dylib, or .dll library.  "<none>" if the library is static only.
set(USED_LIB_LINKTIME_PATH "") # Path to a .a or .lib static library, or an import library
set(USED_LIB_NAME "") # contains the library names as supplied to the linker.


# Like using_external_library, but accepts multiple paths.
macro(using_external_libraries)	
	foreach(LIBRARY_PATH ${USING_EXTERNAL_UNPARSED_ARGUMENTS})
		using_external_library(${LIBRARY_PATH})
	endforeach()
endmacro(using_external_libraries)


# Notify the packager that an external library is being used
# If a Windows import library as passed as an argument, will automatically find and add the corresponding DLL
macro(using_external_library LIBPATH)
	
	if("${LIBPATH}" STREQUAL "" OR NOT EXISTS "${LIBPATH}")
		message(FATAL_ERROR "Non-existant library ${LIBPATH} recorded as a used library")
	endif()
	
	if(NOT ("${USED_LIB_RUNTIME_PATH}" MATCHES "${LIBPATH}" OR "${USED_LIB_LINKTIME_PATH}" MATCHES "${LIBPATH}"))
		is_static_library("${LIBPATH}" LIB_IS_STATIC)
	
		if(TARGET_SUPPORTS_IMPORT_LIBRARIES)
			test(LIB_IS_IMPORT ${LIBPATH} MATCHES ".*${CMAKE_IMPORT_LIBRARY_SUFFIX}")
		else()
			set(LIB_IS_IMPORT FALSE)
		endif()
	
		# Figure out the library name that you'd feed to the linker from the filename
		# --------------------------------------------------------------------
	
		# get full library name
		get_filename_component(LIBNAME ${LIBPATH} NAME)
	
		#remove prefix
		string(REGEX REPLACE "^lib" "" LIBNAME ${LIBNAME})
	
		#remove numbers after the file extension
		string(REGEX REPLACE "(\\.[0-9])+$" "" LIBNAME ${LIBNAME})
		
		#remove the file extension
	
		if(TARGET_SUPPORTS_IMPORT_LIBRARIES)
			string(REGEX REPLACE "${CMAKE_IMPORT_LIBRARY_SUFFIX}$" "" LIBNAME ${LIBNAME})
		endif()
	
		if(LIB_IS_STATIC)
			string(REGEX REPLACE "${CMAKE_STATIC_LIBRARY_SUFFIX}\$" "" LIBNAME ${LIBNAME})
		else()
			string(REGEX REPLACE "${CMAKE_SHARED_LIBRARY_SUFFIX}\$" "" LIBNAME ${LIBNAME})
		endif()
	
	
		# if we are on Windows, we need to find the corresponding .dll library if we got an import library
		# --------------------------------------------------------------------
	
		if(LIB_IS_IMPORT AND ${CMAKE_SYSTEM_NAME} STREQUAL Windows)
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
	
		if(LIB_IS_IMPORT)
			list(APPEND USED_LIB_LINKTIME_PATH ${LIBPATH})
			list(APPEND USED_LIB_RUNTIME_PATH ${DLL_LOCATION_${LIBNAME}})
		
			#message("Recorded DLL/implib combo ${LIBNAME}: import library at ${LIBPATH}, DLL at ${DLL_LOCATION_${LIBNAME}}")
		
		elseif(LIB_IS_STATIC)
			list(APPEND USED_LIB_LINKTIME_PATH ${LIBPATH})
			list(APPEND USED_LIB_RUNTIME_PATH "<none>")
		
			#message("Recorded static library ${LIBNAME} at ${LIBPATH}")
		else() # Unix shared library
			list(APPEND USED_LIB_LINKTIME_PATH ${LIBPATH})
			list(APPEND USED_LIB_RUNTIME_PATH ${LIBPATH})
		
			#message("Recorded shared library ${LIBNAME} at ${LIBPATH}")
		endif()
	
		list(APPEND USED_LIB_NAME ${LIBNAME})
	endif()
endmacro(using_external_library)
