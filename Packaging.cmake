# Configuration file for CPack
# accepts the following variables:
# PACKAGE_NAME - name of package, for display to users
# PACKAGE_FILENAME - name of package file
# ICO_ICON - icon of the package, in ICO format.  Can be left undefined.
# ICO_UNINSTALL_ICON - icon for the Windows uninstaller, in ICO format.  Can be left undefined
# ICNS_ICON - icon for the Mac package, in icns format.  Can be left undefined.
# OSX_STARTUP_SCRIPT - shell script to start when double-clicking the file on a Mac. Can be left undefined.
# BUNDLE_IDENTIFIER - OS X bundle identifier string
# BUNDLE_SIGNATURE - four character OS X bundle signature string


#see https://cmake.org/Wiki/CMake:CPackPackageGenerators for documentation on these variables
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${PACKAGE_NAME})
set(CPACK_PACKAGE_FILE_NAME ${PACKAGE_FILENAME})
	
set(CPACK_PACKAGE_NAME ${CPACK_PACKAGE_FILE_NAME})

set(CPACK_PACKAGE_VENDOR "The Amber Developers")

set(CPACK_PACKAGE_VERSION_MAJOR ${${PROJECT_NAME}_MAJOR_VERSION})
set(CPACK_PACKAGE_VERSION_MINOR ${${PROJECT_NAME}_MINOR_VERSION})
set(CPACK_PACKAGE_VERSION_TWEAK ${${PROJECT_NAME}_TWEAK_VERSION})
set(CPACK_PACKAGE_VERSION_PATCH 0)

#set(CPACK_PACKAGE_ICON ${CMAKE_SOURCE_DIR}/amber_logo.bmp)

set(CPACK_PACKAGE_CONTACT "amber@ambermd.org")

set(PACKAGE_TYPE "TBZ2" CACHE STRING "CPack package format to create in packaging mode. Allowed types:
TBZ2 (.tar.bz2 archive), ZIP (.zip archive), NSIS (Windows installer), Bundle (OS X DMG), DEB (Debian package), RPM (RPM package), ")
validate_configuration_enum(PACKAGE_TYPE TBZ2 ZIP NSIS Bundle DEB RPM)

set(CPACK_GENERATOR ${PACKAGE_TYPE})

set(CPACK_STRIP_FILES TRUE)


# --------------------------------------------------------------------
# figure out package category

if(${PACKAGE_TYPE} STREQUAL TBZ2 OR ${PACKAGE_TYPE} STREQUAL TBZ2)
	#archives are simple.  No dependencies, no metadata.
	set(PACK_TYPE_CATEGORY archive)
elseif(${PACKAGE_TYPE} STREQUAL NSIS)
	#Windows installer. Needed libraries must be bundled.
	set(PACK_TYPE_CATEGORY windows-installer)
	
	set(DEFAULT_DLLS "")
	#the CPack way of creating a desktop shortcut seems to be bugged and not work.
	set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS "
	    CreateShortCut \\\"$DESKTOP\\\\${CPACK_PACKAGE_FILE_NAME} ${${PROJECT_NAME}_MAJOR_VERSION}.lnk\\\" \\\"$INSTDIR\\\\amber-interactive.bat\\\"
	")

	set(CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS "
	    Delete \\\"$DESKTOP\\\\${CPACK_PACKAGE_FILE_NAME} ${${PROJECT_NAME}_MAJOR_VERSION}.lnk\\\"
	")

	
	if(MINGW)
		get_filename_component(MINGW_BIN_DIR ${CMAKE_C_COMPILER} DIRECTORY)
		
		# Start with the system runtime libraries
		set(DEFAULT_DLLS ${MINGW_BIN_DIR}/libgfortran-3.dll ${MINGW_BIN_DIR}/libquadmath-0.dll ${MINGW_BIN_DIR}/libgcc_s_seh-1.dll ${MINGW_BIN_DIR}/libwinpthread-1.dll ${MINGW_BIN_DIR}/libstdc++-6.dll)
	
		if(DEFINED OPENMP AND OPENMP)
			list(APPEND DEFAULT_DLLS ${MINGW_BIN_DIR}/libgomp-1.dll)
		endif()
	endif()
	# NOTE: InstallRequiredSystemLibraries takes care of the MSVC runtime libraries, so we don;t need to add them to DEFAULT_DLLS
	
	#When we link directly to a DLL, it ends up in both USED_LIB_RUNTIME_PATH and USED_LIB_LINKTIME_PATH
	#here we filter these out
	set(EXTRA_USED_LIBS "")
	foreach(LIB ${USED_LIB_LINKTIME_PATH})
		list_contains(ALREADY_IN_DLLS_LIST ${LIB} ${USED_LIB_RUNTIME_PATH})
		if(NOT ALREADY_IN_DLLS_LIST)
			list(APPEND EXTRA_USED_LIBS ${LIB})
		endif()
	endforeach()
	
	# get rid of any "<none>" elements in the runtime path list	
	set(USED_DLLS ${USED_LIB_RUNTIME_PATH})
	list(REMOVE_ITEM USED_DLLS <none>)
	
	set(EXTRA_LIBS_TO_BUNDLE "" CACHE STRING "Additional libraries to bundle with the Windows installer for linking with Amber (e.g. from nab programs).  Accepts a semicolon-seperated list.")
	set(EXTRA_DLLS_TO_BUNDLE "" CACHE STRING "Additional DLL files to include with the Windows installer.  Accepts a semicolon-seperated list.")

	set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS ${DEFAULT_DLLS} ${USED_DLLS} ${EXTRA_DLLS_TO_BUNDLE}) #this one gets handled by CMake
	set(LIBS_TO_BUNDLE ${USED_LIBS_MINUS_DUPLICATES} ${EXTRA_LIBS_TO_BUNDLE}) # this one we handle ourselves, because it needs to go into lib instead of bin
	
	install(FILES ${LIBS_TO_BUNDLE} DESTINATION ${LIBDIR})
	
	#NSIS variables
	# --------------------------------------------------------------------
	if(DEFINED ICO_ICON)
		set(CPACK_NSIS_MUI_ICON ${ICO_ICON})
	endif()
	
	if(DEFINED ICO_UNINSTALL_ICON)
		set(CPACK_NSIS_MUI_UNIICON ${ICO_UNINSTALL_ICON})
	endif()
	
	set(CPACK_NSIS_COMPRESSOR "/SOLID lzma" )
	set(CPACK_NSIS_MODIFY_PATH TRUE)
	set(CPACK_NSIS_INSTALLED_ICON_NAME ${CMAKE_SOURCE_DIR}/amber.ico)
	set(CPACK_NSIS_HELP_LINK "http://ambermd.org/doc12/")
	set(CPACK_NSIS_URL_INFO_ABOUT "http://ambermd.org/")
	set(CPACK_NSIS_CONTACT "${CPACK_PACKAGE_CONTACT}")

elseif(${PACKAGE_TYPE} STREQUAL Bundle)
	# OS X .app package.
	set(PACK_TYPE_CATEGORY mac-app)
	
	#OS X bundle
	# --------------------------------------------------------------------
	set(CPACK_BUNDLE_NAME ${CPACK_PACKAGE_FILE_NAME})
	
	if(DEFINED ICNS_ICON)
		set(CPACK_BUNDLE_ICON ${ICNS_ICON})
	endif()
	
	if(DEFINED OSX_STARTUP_SCRIPT)
		set(CPACK_BUNDLE_STARTUP_COMMAND ${OSX_STARTUP_SCRIPT})
	endif()
	
   	set(ICON_FILE_NAME "${CPACK_BUNDLE_NAME}")

	#CFBundleGetInfoString
	set(MACOSX_BUNDLE_INFO_STRING "${CPACK_PACKAGE_DESCRIPTION_SUMMARY} Version ${${PROJECT_NAME}_VERSION}, Copyright ${CPACK_PACKAGE_VENDOR}")
	set(MACOSX_BUNDLE_ICON_FILE ${ICON_FILE_NAME})
	set(MACOSX_BUNDLE_GUI_IDENTIFIER "${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")
	#CFBundleLongVersionString
	set(MACOSX_BUNDLE_LONG_VERSION_STRING "${CPACK_PACKAGE_DESCRIPTION_SUMMARY} Version ${${PROJECT_NAME}_VERSION}")
	set(MACOSX_BUNDLE_SHORT_VERSION_STRING ${${PROJECT_NAME}_VERSION})
	
	set(CONFIGURED_PLIST_PATH ${CMAKE_BINARY_DIR}/packaging/Info.plist)
	
	configure_file(${CMAKE_CURRENT_LIST_DIR}/packaging/Info.in.plist ${CONFIGURED_PLIST_PATH} @ONLY)
	set(CPACK_BUNDLE_PLIST ${CONFIGURED_PLIST_PATH})
		
	# Find libraries to bundle
	# --------------------------------------------------------------------
	set(EXTRA_LIBS_TO_BUNDLE "" CACHE STRING "Additional libraries to bundle with the OS X distribution.  Accepts a semicolon-seperated list.")
	
	set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS ${USED_LIB_RUNTIME_PATH} ${EXTRA_LIBS_TO_BUNDLE}) # RUNTIME and LINKTIME paths are the same on Macs, so we don't need to bother with USED_LIB_LINKTIME_PATH
	list(REMOVE_ITEM CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS "<none>")
	
else()
	# Linux package
	set(PACK_TYPE_CATEGORY linux-package)
	
	# install to install prefix, rather than root directory as with every other package
	set(CPACK_PACKAGING_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
	set(CPACK_PACKAGE_DEFAULT_LOCATION ${CMAKE_INSTALL_PREFIX})
	
	#Debian package
	if(${TARGET_ARCH} STREQUAL "x86_64")
		set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE amd64)
	else()
		set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${TARGET_ARCH})
	endif()

	set(DEB_PACKAGE_DEPENDENCIES "" CACHE STRING "Dependencies string for the debian package.  Must be written by the packager according to how they built amber.
	 Example: \"libarpack2 (>= 3.0.2-3), liblapack3gf (>= 3.3.1-1), libblas3gf (>= 1.2.20110419-2ubuntu1), libreadline6 (>= 6.3-4ubuntu2)\"")
	
	set(CPACK_DEBIAN_PACKAGE_DEPENDS ${DEB_PACKAGE_DEPENDENCIES})
	set(CPACK_DEBIAN_PACKAGE_SECTION "science")
	
	#RPM package
	set(CPACK_RPM_PACKAGE_RELEASE 1)
	set(CPACK_RPM_PACKAGE_GROUP "Applications/Productivity")
	set(RPM_PACKAGE_DEPENDENCIES  "" CACHE STRING "Requirements string for the RPM package.  Must be written by the packager according to how they built amber.
	 Example: \"python >= 2.7.0, lapack, blas\"")
	set(CPACK_RPM_PACKAGE_REQUIRES ${RPM_PACKAGE_DEPENDENCIES})
		
endif()

# --------------------------------------------------------------------


include(InstallRequiredSystemLibraries)

include(CPack)

# --------------------------------------------------------------------
# packaging report config

option(PRINT_PACKAGING_REPORT "Print a report showing data which will help you package ${PROJECT_NAME}." FALSE)

function(print_packaging_report)
	# calculate external libraries used by amber

	
	colormsg(HIGREEN "**************************************************************************")
	colormsg("                             " _WHITE_ "Packaging Report")
	colormsg(HIGREEN "**************************************************************************")
	colormsg("Package type:         " HIBLUE "${PACKAGE_TYPE}")
	colormsg("Package category:     " HIBLUE "${PACK_TYPE_CATEGORY}")
	colormsg("External libraries used by ${PROJECT_NAME}:")
	colormsg(HIGREEN "--------------------------------------------------------------------------")
	foreach(LIBNAME ${USED_LIB_NAME})
		# find library's index in the list
		list(FIND USED_LIB_NAME ${LIBNAME} LIB_INDEX)
		
		list(GET USED_LIB_LINKTIME_PATH ${LIB_INDEX} LINKTIME_PATH)
		list(GET USED_LIB_RUNTIME_PATH ${LIB_INDEX} RUNTIME_PATH)
		if(${RUNTIME_PATH} STREQUAL "<none>" OR ${RUNTIME_PATH} STREQUAL ${LINKTIME_PATH})
			colormsg("${LIBNAME} -" YELLOW "${LINKTIME_PATH}")
		else()
			colormsg("${LIBNAME} -" YELLOW "${LINKTIME_PATH} (link time)," MAG "${RUNTIME_PATH} (runtime)")
		endif()	
	endforeach()
	colormsg(HIGREEN "**************************************************************************")
	
	colormsg("")
	
	if(${PACK_TYPE_CATEGORY} STREQUAL windows-installer)
		colormsg("Since this is a Windows installer, it needs to bundle all of the DLLs that Amber needs with it (besides the Microsoft runtime libraries).  Currently, the following DLLs will be bundled:")
		colormsg("")
		foreach(LIBRARY ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS})
			colormsg(HIGREEN ${LIBRARY})
		endforeach()
		colormsg("")
		colormsg("Please ensure that all DLLs used by amber executables are included in this list.  If any more need to be added, list them in the variable EXTRA_DLLS_TO_BUNDLE.")
		
		colormsg("")
		colormsg("Also, in order for the Nab compiler to work, all of the libraries required to link with Amber (besides DLLS that are already bundled and don't have import libraries) need to be in the Amber lib folder.")
		
		if("${LIBS_TO_BUNDLE}" STREQUAL "")
			colormsg("Currently, no libraries are bundled.")
		else()
			colormsg("Currently, the following libraries will be bundled:")
			colormsg("")
			foreach(LIBRARY ${LIBS_TO_BUNDLE})
				colormsg(HIGREEN ${LIBRARY})
			endforeach()
			colormsg("")
		endif()
		colormsg("Please ensure that all libraries used by amber are included in this list.  If any more need to be added, list them in the variable EXTRA_LIBS_TO_BUNDLE.")
	elseif(${PACK_TYPE_CATEGORY} STREQUAL mac-app)
		colormsg("This is an OS X application, so it needs to bundle the libraries it uses. Currently, the following libraries will be bundled:")
		foreach(LIBRARY ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS})
			colormsg(HIGREEN ${LIBRARY})
		endforeach()
		
		colormsg("Please ensure that all libraries used by Amber's executables are included in this list.")
		colormsg("If any libraries are missing, please list them in the variable EXTRA_LIBS_TO_BUNDLE")
	elseif(${PACK_TYPE_CATEGORY} STREQUAL linux-package)
		colormsg("This is a Linux package, so dependencies will be automatically calculated for the current distro you are building on.")
	endif()
colormsg(HIGREEN "**************************************************************************")
	
endfunction(print_packaging_report)