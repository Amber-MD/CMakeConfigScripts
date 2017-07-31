#-------------------------------------------------------------------------------
# Find Python
#-------------------------------------------------------------------------------
option(USE_MINICONDA "If set, Amber will download, configure, and use an instance of Continuuum's Miniconda interpreter.  Recommended if you are having problems with the system Python" FALSE)

if(USE_MINICONDA)

	set(MINICONDA_WANTED_VERSION 2)
	include(UseMiniconda)
	download_and_use_miniconda()
	set(PYTHON_EXECUTABLE ${MINICONDA_PYTHON})
	set(BUILD_PYTHON_DEFAULT TRUE)
	set(HAS_PYTHON TRUE)
else()
		
	find_package(PythonInterp)
	
	#used to know if we can run Python scripts
	set(HAS_PYTHON ${PYTHONINTERP_FOUND})
	
	# get a single version number
	set(PYTHON_VERSION "${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}")

	test(PYTHON_VERSION_OK (${PYTHON_VERSION} VERSION_GREATER 2.6 AND ${PYTHON_VERSION} VERSION_LESS 3.0) OR ${PYTHON_VERSION} VERSION_GREATER 3.3)
	
	if(PYTHON_VERSION_OK)
		message(STATUS "Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} -- OK")
	else()
		message(STATUS "Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} -- Not OK, need version 2.7 or >= 3.4")
	endif()
	
	test(BUILD_PYTHON_DEFAULT HAS_PYTHON AND PYTHON_VERSION_OK)
endif()

option(BUILD_PYTHON "Whether to build the Python programs and libraries." ${BUILD_PYTHON_DEFAULT})

if(BUILD_PYTHON)
	if(NOT HAS_PYTHON)
		message(FATAL_ERROR "You requested to build the python packages, but the Python interpereter was not found.")
	endif()
	if(NOT PYTHON_VERSION_OK)
		message(FATAL_ERROR "You requested to build the python packages, but the Python interpereter is an unsupported version (${PYTHON_VERSION}).  Please set PYTHON_EXECUTABLE to point to a python interpreter of the correct version, or disable BUILD_PYTHON.")
	endif()
else()
	message(STATUS "Skipping build of Python packages.")
endif()

#-------------------------------------------------------------------------------
#  See where we want to install our Python packages (and make sure it's legal)
#-------------------------------------------------------------------------------

set(PYTHON_INSTALL LOCAL CACHE STRING "Place to install python packages.  Values: LOCAL (<install-prefix>/lib), HOME ($HOME/.local/lib), GLOBAL (system package directory)")
set(PYTHON_INSTALL_VALID_VALUES LOCAL HOME GLOBAL)

#-------------------------------------------------------------------------------
#  Build parts of installation commands
#-------------------------------------------------------------------------------

# for SOME REASON, things don't work properly on Windows unless the Python prefix argument uses backslashes.
# I have NO IDEA why
# so we have to execute this bit of code in every Python program's cmake_install.cmake to create CMAKE_INSTALL_PREFIX_BS
if(WIN32)
	set(FIX_BACKSLASHES_CMD [==[string(REPLACE "/" "\\" CMAKE_INSTALL_PREFIX_BS "${CMAKE_INSTALL_PREFIX}/")]==])
else()
	set(FIX_BACKSLASHES_CMD [==[set(CMAKE_INSTALL_PREFIX_BS "${CMAKE_INSTALL_PREFIX}/")]==])
endif()

if(BUILD_PYTHON)
	validate_configuration_enum(PYTHON_INSTALL ${PYTHON_INSTALL_VALID_VALUES})
	
	if(${PYTHON_INSTALL} STREQUAL LOCAL)
		set(PYTHON_PREFIX_ARG \"--prefix=\${CMAKE_INSTALL_PREFIX_BS}\")
		
	elseif(${PYTHON_INSTALL} STREQUAL HOME)
		set(PYTHON_PREFIX_ARG --user)
	else()
		set(PYTHON_PREFIX_ARG "")
	endif()
endif()

if(MINGW)
	set(PYTHON_COMPILER_ARG "--compiler=mingw32")
	
	# force Python to use the MinGW compiler
	set(PYTHON_CXX_ENVVAR_ARG CXX=${CMAKE_CXX_COMPILER})
else()
	set(PYTHON_COMPILER_ARG "")
	
	if(CROSSCOMPILE)
		set(PYTHON_CXX_ENVVAR_ARG CXX=${CMAKE_CXX_COMPILER})
	else()
		# allow Python to use whatever compiler it wants, since object file formats are usually the same on Unix
		set(PYTHON_CXX_ENVVAR_ARG "")
	endif() 
endif()

# We also need to define MS_WIN64 on 64 bit windows
if(${CMAKE_SYSTEM_NAME} STREQUAL Windows AND ${TARGET_ARCH} STREQUAL x86_64)
	set(WIN64_DEFINE_ARG -DMS_WIN64)
else()
	set(WIN64_DEFINE_ARG "")
endif()

#------------------------------------------------------------------------------
#  Checks the selected python is compatible with Amber.
#
#  Fails if it is not.
#------------------------------------------------------------------------------



if(BUILD_PYTHON)	
		verify_python_package(numpy)
		verify_python_package(scipy)
		verify_python_package(matplotlib)
		
		# apparantly tkinter is not capitalized in some environments (???????)
		check_python_package(tkinter HAVE_TKINTER)
		check_python_package(Tkinter HAVE_TKINTER)
		
		if(NOT HAVE_TKINTER)
			message(FATAL_ERROR "Could not find the Python Tkinter package.  You must install tk through your package manager (python-tk on Ubuntu, tk on Arch),\
 and the tkinter Python package will get installed.  If you cannot get Tkinter, disable BUILD_PYTHON to skip building Python packages.")
		endif()
		

		if(NOT AMBER_RELEASE)
			verify_python_package(cython)
		endif()
		
		# this one has a different error message
		check_python_package(distutils.sysconfig HAVE_DISTUTILS_SYSCONFIG)
		if(NOT HAVE_DISTUTILS_SYSCONFIG)
			message(FATAL_ERROR "You need to install the Python development headers!")
		endif()
endif()

#Macro to install a python library using distutils when make install is run.
#Runs the setup.py in the current source directory
#Args: arguments to pass to the python script

if(BUILD_PYTHON)
	
	macro(install_python_library) # ARGUMENTS
				
        install(CODE "
        ${FIX_BACKSLASHES_CMD}
        execute_process(
		    COMMAND \"${PYTHON_EXECUTABLE}\"
		    ./setup.py build -b \"${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/python-build\"
		    install -f ${PYTHON_PREFIX_ARG}
		    \"--install-scripts=\${CMAKE_INSTALL_PREFIX_BS}${BINDIR}\"
		    ${ARGN}
		    WORKING_DIRECTORY \"${CMAKE_CURRENT_SOURCE_DIR}\")")
		    
	endmacro(install_python_library)
else()
	macro(install_python_library) # ARGUMENTS
		#do nothing
	endmacro(install_python_library)
  
endif()
