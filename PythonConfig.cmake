
option(BUILD_PYTHON "Whether to build the Python programs and libraries." TRUE)

if(BUILD_PYTHON)
	
	#-------------------------------------------------------------------------------
	# Find Python
	#-------------------------------------------------------------------------------
	option(USE_MINICONDA "If set, Amber will download, configure, and use an instance of Continuuum's Miniconda interpreter.  Recommended if you are having problems with the system Python" TRUE)
	
	if(USE_MINICONDA)
	
		set(MINICONDA_VERSION 4.3.21) 
		option(MINICONDA_USE_PY3 "If true, Amber will download a Python 3 miniconda when USE_MINICONDA is enabled.  Otherwise, Python 2.7 Miniconda will get downloaded." FALSE)
		
		include(UseMiniconda)
		download_and_use_miniconda()
		
		set(PYTHON_EXECUTABLE ${MINICONDA_PYTHON})
		
	else()
			
		find_package(PythonInterp)
		
		#used to know if we can run Python scripts
		set(HAS_PYTHON ${PYTHONINTERP_FOUND})
		
		# get a single version number
		set(PYTHON_VERSION "${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}")
	
		test(PYTHON_VERSION_OK (${PYTHON_VERSION} VERSION_GREATER 2.6 AND ${PYTHON_VERSION} VERSION_LESS 3.0) OR ${PYTHON_VERSION} VERSION_GREATER 3.3)
		
		if(NOT HAS_PYTHON)
			message(FATAL_ERROR "You requested to build the python packages, but the Python interpereter was not found.  Either enable USE_MINICONDA, \
or set PYTHON_EXECUTABLE to point to your Python interpreter.")
		endif()
		
		if(PYTHON_VERSION_OK)
			message(STATUS "Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} -- OK")
		else()
			message(FATAL_ERROR "Your Python is version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.  This is not OK, version 2.7 or >= 3.4 is required.  \
Either disable BUILD_PYTHON, or set PYTHON_EXECUTABLE to point to a compatible Python.")
		endif()
		
		#------------------------------------------------------------------------------
		#  Checks the selected python is compatible with Amber.
		#
		#  Fails if it is not.
		#
		#  We try to aggregate all missing packages into a single error message.
		#------------------------------------------------------------------------------
		

		
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
			
			set(ERROR_MESSAGE "${ERROR_MESSAGE}.  Please install these and try again, or set USE_MINICONDA to TRUE to create a python environment automatically.")
			
			message(FATAL_ERROR ${ERROR_MESSAGE})
		endif()
		
		# --------------------------------------------------------------------
		# apparantly tkinter is not capitalized in some environments (???????)
		check_python_package(tkinter HAVE_TKINTER)
		check_python_package(Tkinter HAVE_TKINTER)
		
		if(NOT HAVE_TKINTER)
			message(FATAL_ERROR "Could not find the Python Tkinter package.  You must install tk through your package manager (python-tk on Ubuntu, tk on Arch),\
	 and the tkinter Python package will get installed.  If you cannot get Tkinter, disable BUILD_PYTHON to skip building Python packages, or enable USE_MINICONDA.")
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
	# pass this arg to cmake -E env to make it so
	set(PYTHONPATH_SET_CMD "\"PYTHONPATH=\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages\"")
	
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
