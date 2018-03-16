# This file is run during 2nd init to check the results of AmberCompilerConfig.

# the necessity for this check is discussed here: https://github.com/Amber-MD/CMakeConfigScripts/issues/4
if("${COMPILER}" STREQUAL GNU)
	
	foreach(LANG C CXX)
		if("${CMAKE_${LANG}_COMPILER_ID}" STREQUAL Clang OR "${CMAKE_${LANG}_COMPILER_ID}" STREQUAL AppleClang)
			message(FATAL_ERROR "You told Amber to use the GNU compilers, and it searched for compiler executables named \"gcc\" and \"g++\", but the ${LANG} compiler \
executable that it found (${CMAKE_${LANG}_COMPILER}) is actually Clang masquerading as GCC.  This is common on certain Mac systems.  While Amber could build fine using Clang, \
you requested GCC, so Amber has stopped the build to notify you.  There are three ways to fix this.  

(1) To continue using Clang, you could delete and recreate your build directory, and rerun the build with COMPILER set to \"clang\", or to \"auto\".
(2) If you installed gcc and gfortran through MacPorts/Homebrew/something else, then move the directory containing the real gcc to the front of your PATH, \
then delete and recreate your build directory and try again.
(3) If you have GCC on your system but don't want to mess with your PATH, then delete and recreate your build directory, then rebuild and set the CMake variables \
CMAKE_C_COMPILER and CMAKE_CXX_COMPILER to point to gcc and g++.
")
		endif()
	endforeach()
endif()

# on Unix systems, check that we have write permissions to install directory
if(HOST_LINUX OR HOST_OSX)
	install(CODE "
execute_process(COMMAND mkdir -p \$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX} || true
	COMMAND test -w \$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX} 
	RESULT_VARIABLE TEST_WRITABLE_RESULT)
if(NOT TEST_WRITABLE_RESULT EQUAL 0)
	message(FATAL_ERROR \"Cannot write to the installation directory \$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}.  Please run the installation as superuser, or change CMAKE_INSTALL_PREFIX to point to a directory that you have write access to.\")
endif()" COMPONENT Serial)
endif()
