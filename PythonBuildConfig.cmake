
option(BUILD_PYTHON "Whether to build the Python programs and libraries." ${HAS_PYTHON})

if(BUILD_PYTHON AND NOT HAS_PYTHON)
	message(WARNING "BUILD_PYTHON is enabled, but python was not found.  Python packages will be disabled until Python is found.")
	
	# create a local variable shadowing the cache variable
	set(BUILD_PYTHON FALSE)
endif()

if(BUILD_PYTHON)
	
		
	#------------------------------------------------------------------------------
	#  Checks the selected python is compatible with Amber.
	#
	#  Fails if it is not.
	#
	#  We try to aggregate all missing packages into a single error message.
	#------------------------------------------------------------------------------

	option(SKIP_PYTHON_PACKAGE_CHECKS "If true, the buildscript will not verify that you have the needed Python packages to run Amber's Python programs." FALSE)
	
	if(NOT SKIP_PYTHON_PACKAGECHECKS)
		
		# check "normal" packages
		# --------------------------------------------------------------------
		check_python_package(numpy HAVE_NUMPY)
		check_python_package(scipy HAVE_SCIPY)
		check_python_package(matplotlib HAVE_MATPLOTLIB)
		
		if(AMBER_RELEASE)
			# cython is not needed since pytraj will have been pre-cythonized
			set(HAVE_CYTHON TRUE)
		else()
			check_python_package(cython HAVE_CYTHON)
		endif()
		
		if(NOT (HAVE_NUMPY AND HAVE_SCIPY AND HAVE_MATPLOTLIB AND HAVE_CYTHON))
			
			set(ERROR_MESSAGE "Missing required Python packages:")
			
			# add missing packages to string
			foreach(PACKAGE numpy scipy matplotlib cython)
				string(TOUPPER ${PACKAGE} PACKAGE_UCASE)
				if(NOT HAVE_${PACKAGE_UCASE})
					set(ERROR_MESSAGE "${ERROR_MESSAGE} ${PACKAGE}")
				endif()
			endforeach()
			
			set(ERROR_MESSAGE "${ERROR_MESSAGE}.  Please install these and try again.  If you cannot install them, you may set BUILD_PYTHON to FALSE to \
skip building Python packages, or set DOWNLOAD_MINICONDA to TRUE to create a python environment automatically.")
			
			message(FATAL_ERROR ${ERROR_MESSAGE})
		endif()
		
		# --------------------------------------------------------------------
		# apparantly tkinter is not capitalized in some environments (???????)
		check_python_package(tkinter HAVE_TKINTER)
		check_python_package(Tkinter HAVE_TKINTER)
		
		if(NOT HAVE_TKINTER)
			message(FATAL_ERROR "Could not find the Python Tkinter package.  You must install tk through your package manager (python-tk on Ubuntu, tk on Arch),\
	 and the tkinter Python package will get installed.  If you cannot get Tkinter, disable BUILD_PYTHON to skip building Python packages, or enable DOWNLOAD_MINICONDA.")
		endif()
		
		# --------------------------------------------------------------------
		# this one has a different error message
		check_python_package(distutils.sysconfig HAVE_DISTUTILS_SYSCONFIG)
		if(NOT HAVE_DISTUTILS_SYSCONFIG)
			message(FATAL_ERROR "You need to install the Python development headers!")
		endif()
	endif()
		
	#-------------------------------------------------------------------------------
	#  Build parts of installation commands
	#-------------------------------------------------------------------------------
	
	# for SOME REASON, things don't work properly on Windows unless the Python prefix argument uses backslashes.
	# I have NO IDEA why
	# so we have to execute this bit of code in every Python program's cmake_install.cmake to create CMAKE_INSTALL_PREFIX_BS
	if(WIN32)
		set(FIX_BACKSLASHES_CMD [==[string(REPLACE "/" "\\" CMAKE_INSTALL_PREFIX_BS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/")]==])
	else()
		set(FIX_BACKSLASHES_CMD [==[set(CMAKE_INSTALL_PREFIX_BS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/")]==])
	endif()
	
	
	# Amber's Python programs must be installed with the PYTHONPATH set to the install directory
	# so determine the Python prefix relative to AMBERHOME
	
	if(NOT ((DEFINED PREFIX_RELATIVE_PYTHONPATH) AND ("${PYTHON_EXECUTABLE}" STREQUAL "${PY_INTERP_FOR_RELATIVE_PYTHONPATH}")))
	
		# determine key for INSTALL_SCHEMES
		if(TARGET_WINDOWS)
			set(SCHEME_KEY "nt")
		else()
			set(SCHEME_KEY "unix_prefix")
		endif()
	
		# this was REALLY hard to figure out.  Seriously, I've created entire programs' build files in less time than it took to get this command working on all systems.
		# This command peeks into the guts of distutils to see what the package installer thinks the install prefix is.
		# Any solution involving sys.prefix doesn't work on all Linux distros since that seems to be incorrect on some installations
		execute_process(
			COMMAND "${PYTHON_EXECUTABLE}" 
				-c "import sys; from distutils.command.install import INSTALL_SCHEMES; print(INSTALL_SCHEMES['${SCHEME_KEY}']['purelib'].replace('$py_version_short', (str.split(sys.version))[0][0:3]).replace('$base', ''))"
			RESULT_VARIABLE PYTHONPATH_CMD_RESULT
			OUTPUT_VARIABLE PYTHONPATH_CMD_OUTPUT
			ERROR_VARIABLE PYTHONPATH_CMD_STDERR
			OUTPUT_STRIP_TRAILING_WHITESPACE)
		
		if(NOT "${PYTHONPATH_CMD_RESULT}" EQUAL 0)
			message(FATAL_ERROR "Failed to determine relative PYTHONPATH: python command failed with error ${PYTHONPATH_CMD_STDERR}")
		endif()
		
		# convert backslashes to forward slashes
		file(TO_CMAKE_PATH "${PYTHONPATH_CMD_OUTPUT}" PYTHONPATH_CMD_OUTPUT)
		
		message(STATUS "Python relative site-packages location: <prefix>${PYTHONPATH_CMD_OUTPUT}")
		
		set(PREFIX_RELATIVE_PYTHONPATH "${PYTHONPATH_CMD_OUTPUT}" CACHE INTERNAL "Install folder of Python modules relative to the prefix they're installed to with setup.py install --prefix.")
		
		set(PY_INTERP_FOR_RELATIVE_PYTHONPATH ${PYTHON_EXECUTABLE} CACHE INTERNAL "The python interpreter used to run the PREFIX_RELATIVE_PYTHONPATH check" FORCE)
	endif()
			
	set(PYTHONPATH_SET_CMD "\"PYTHONPATH=\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}${PREFIX_RELATIVE_PYTHONPATH}\"")
	
	# argument to force Python packages to get installed into the Amber install dir
	set(PYTHON_PREFIX_ARG \"--prefix=\${CMAKE_INSTALL_PREFIX_BS}\")
	
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
		
	#Macro to install a python library using distutils when make install is run.
	#Runs the setup.py in the current source directory
	#Args: arguments to pass to the python script
	macro(install_python_library) # ARGUMENTS
	
		list_to_space_separated(ARGN_SPC ${ARGN})
				
        install(CODE "
        ${FIX_BACKSLASHES_CMD}
        execute_process(
		    COMMAND \"${CMAKE_COMMAND}\" -E env
		     ${PYTHONPATH_SET_CMD}
		     \"${PYTHON_EXECUTABLE}\"
		    ./setup.py build -b \"${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/python-build\"
		    install -f ${PYTHON_PREFIX_ARG}
		    \"--install-scripts=\${CMAKE_INSTALL_PREFIX_BS}${BINDIR}\"
		    ${ARGN_SPC}
		    WORKING_DIRECTORY \"${CMAKE_CURRENT_SOURCE_DIR}\")"
		    COMPONENT Python)
		    
	endmacro(install_python_library)
	
	
else() # BUILD_PYTHON disabled
	
	
	macro(install_python_library) # ARGUMENTS
		#do nothing
	endmacro(install_python_library)
endif()
