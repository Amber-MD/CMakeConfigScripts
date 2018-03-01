# script which finds a Python interpereter.
# It detects a system Anaconda, offers to download an internal Miniconda, and, as a last resort, will use the system Python.

# NOTE: It is a problem if the user has Anaconda on their PATH but we do not use it.  It contains shared libraries
# with different symbols than the system versions, so CMake will complain that it can't generate a safe RPATH

# --------------------------------------------------------------------
# Detect system Anaconda

find_program(CONDA conda)

if(EXISTS "${CONDA}")
	
	get_filename_component(ANACONDA_BIN "${CONDA}" DIRECTORY)
	get_filename_component(ANACONDA_ROOT "${ANACONDA_BIN}/.." REALPATH)
	
	set(USING_SYSTEM_ANACONDA TRUE)
	
	message(STATUS "Found system Anaconda at ${ANACONDA_ROOT}.  It will be used as a Python interpereter, and for additional shared libraries.")
	message(STATUS "It is not possible to avoid using Anaconda if it is on the PATH.  To build Amber without using Anaconda, remove it from your PATH.")
	message(STATUS "To use a different Anaconda install, just move it to the front of your PATH and rerun CMake.")
	message(STATUS "To change the Python interpreter in use to a different one inside Anaconda, set the PYTHON_EXECUTABLE variable to point to it.")
	
	if(DEFINED DOWNLOAD_MINICONDA)
		if(DOWNLOAD_MINICONDA)
			message(FATAL_ERROR "DOWNLOAD_MINICONDA is TRUE, but this will be ignored because Anaconda was found on your path.  Please set DOWNLOAD_MINICONDA to FALSE, or remove Anaconda from your PATH.")
		endif()
	endif() 
	
	list(APPEND CMAKE_LIBRARY_PATH "${ANACONDA_ROOT}/lib")
	list(APPEND CMAKE_INCLUDE_PATH "${ANACONDA_ROOT}/include")
	list(APPEND CMAKE_PROGRAM_PATH "${ANACONDA_BIN}")
	
else()
	set(USING_SYSTEM_ANACONDA FALSE)
endif()

# --------------------------------------------------------------------
# Offer to download Miniconda

if(NOT USING_SYSTEM_ANACONDA)

	if(NOT DEFINED DOWNLOAD_MINICONDA)
		
		# Stop the build to give the user a choice
		option(DOWNLOAD_MINICONDA "If true, then Amber will download its own Miniconda distribution.  Recommended if you're having problems with the system Python interpereter." TRUE)
	
	
		message(FATAL_ERROR "We highly recommend letting AMBER install a Python environment with all prerequisites inside \
Amber's install location via a Continuum Miniconda distribution. \
Miniconda is chosen because it comes with a great package manager, conda, which is \
specially designed for numerical and scientific computing. This makes compiling \
AMBER Python extensions much easier. \
This will only need to be done once. \
It may take several minutes and downloads around a hundred megabytes of data. \

Config variable DOWNLOAD_MINICONDA has been autoset to TRUE.  To accept and download Miniconda, just run cmake again. \
If you do not want to download Miniconda, run cmake again with DOWNLOAD_MINICONDA set to FALSE.")

	endif()
	
endif()

# --------------------------------------------------------------------
# Find the actual interpreter

if((NOT USING_SYSTEM_ANACONDA) AND DOWNLOAD_MINICONDA)
	set(MINICONDA_VERSION 4.3.21) 
	option(MINICONDA_USE_PY3 "If true, Amber will download a Python 3 miniconda when DOWNLOAD_MINICONDA is enabled.  Otherwise, Python 2.7 Miniconda will get downloaded." FALSE)
	
	include(UseMiniconda)
	download_and_use_miniconda()
	
	set(PYTHON_EXECUTABLE ${MINICONDA_PYTHON})
	set(HAS_PYTHON TRUE)
	
else()

	#-------------------------------------------------------------------------------
	# Find a system Python, or Anaconda's python if we are using external Anaconda
	#-------------------------------------------------------------------------------
	find_package(PythonInterp)
	
	#used to know if we can run Python scripts
	set(HAS_PYTHON ${PYTHONINTERP_FOUND})
	
	# get a single version number
	set(PYTHON_VERSION "${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}")

	test(PYTHON_VERSION_OK (${PYTHON_VERSION} VERSION_GREATER 2.6 AND ${PYTHON_VERSION} VERSION_LESS 3.0) OR ${PYTHON_VERSION} VERSION_GREATER 3.3)
	
	if(NOT HAS_PYTHON)
		message(STATUS "Python interpereter not found.  Python packages will not be built, and the updater will not run. \
Either enable DOWNLOAD_MINICONDA, or set PYTHON_EXECUTABLE to point to your Python interpreter.")
	endif()
	
	if(PYTHON_VERSION_OK)
		message(STATUS "Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} -- OK")
	else()
		message(STATUS "Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} -- Not OK.  Version 2.7 or >= 3.4 is required.  \
Python packages will not be built, and the updater will not run. \
Either enable DOWNLOAD_MINICONDA, or set PYTHON_EXECUTABLE to point to a Python interpreter of the correct version.")
		
		set(HAS_PYTHON FALSE)
	endif()
	
	# set up amber.python symlink to point to active python interpereter
	# (this could break if the install is moved to a different computer, but it's the best we can do)
	if((HOST_OSX OR HOST_LINUX) AND (TARGET_OSX OR TARGET_LINUX))
    	install(CODE "execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${PYTHON_EXECUTABLE} \$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/bin/amber.python)" COMPONENT Python)
    endif()
endif()