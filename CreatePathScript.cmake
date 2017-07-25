#CMake file which creates amber.sh and amber.csh, which are sourced by users to set all of the variables for using amber.

if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
	#create batch file
	message(STATUS "Generating amber.bat")
	
	set(VAR_FILE_BAT ${CMAKE_CURRENT_BINARY_DIR}/amber.bat)
	
	# Miniconda needs to be added to that path if we're using it
	if(USE_MINICONDA)
		set(MINICONDA_EXTRA_PATH_FOLDERS "%AMBERHOME%\\miniconda;%AMBERHOME%\\miniconda\\Scripts;")
	else()
		set(MINICONDA_EXTRA_PATH_FOLDERS "")
	endif()
	
	# write base content of file
	file(WRITE ${VAR_FILE_BAT} "@echo off
rem Run this script to add the variables necessary to use Amber to your shell.
rem This script must be located in the Amber root folder!
	
set AMBERHOME=%~dp0
set AMBERHOME=%AMBERHOME:~0,-1%

set PATH=%AMBERHOME%\\bin;${MINICONDA_EXTRA_PATH_FOLDERS}%PATH%")
	
	# perl path
	if(BUILD_PERL)
		# get windows path for perl lib
		string(REPLACE "/" "\\" PERL_MODULE_DIR_WIN ${PERL_MODULE_DIR})
		file(APPEND ${VAR_FILE_BAT} "
set PERL5LIB=%AMBERHOME%\\${PERL_MODULE_DIR_WIN}")
	endif()

	# python path
	if(BUILD_PYTHON)
		file(APPEND ${VAR_FILE_BAT} "
set PYTHONPATH=%AMBERHOME%\\lib\\site-packages:%PYTHONPATH%")
	endif()
	
	install(PROGRAMS ${VAR_FILE_BAT} DESTINATION ".")
	
	#wrapper script which starts an interactive shell.
	install(PROGRAMS ${CMAKE_SOURCE_DIR}/cmake-packaging/amber-interactive.bat DESTINATION ".")

else()
	set(SOURCE_FILE_SH ${CMAKE_CURRENT_BINARY_DIR}/amber.sh) # "source file" as in the bash "source" command
	set(SOURCE_FILE_CSH ${CMAKE_CURRENT_BINARY_DIR}/amber.csh)
	
	#NOTE: in CMake, you have to escape quotes and dollar signs in strings.
	
	message(STATUS "Generating amber.sh")
	
	# if we are using Miniconda, we have to add it to the path because it lives in a seperate directory
	# Unlike the old build system, we do not symlink miniconda into AMBERHOME/bin

	if(${CMAKE_SYSTEM_NAME} STREQUAL Darwin)
		set(LIB_PATH_VAR DYLD_LIBRARY_PATH)
	else()
		set(LIB_PATH_VAR LD_LIBRARY_PATH)
	endif() 
	
	# if we're using minconda, we need to add that to the path
	if(USE_MINICONDA)
		set(MINICONDA_PATH_PART "\${AMBERHOME}/miniconda/bin:")
	else()
		set(MINICONDA_PATH_PART "")
	endif()
    
    # NOTE: we can't (always) use $0 to find the path to the script because it is being sourced
    # so we use a thing from http://unix.stackexchange.com/questions/96203/find-location-of-sourced-shell-script
	file(WRITE ${SOURCE_FILE_SH} 
"# Source this script to add the variables necessary to use AMBER to your shell.

if [ -n \"$BASH_SOURCE\" ]; then
    this_script=\"$BASH_SOURCE\"
elif [ -n \"$DASH_SOURCE\" ]; then
    this_script=\"$DASH_SOURCE\"
elif [ -n \"$ZSH_VERSION\" ]; then
    setopt function_argzero
    this_script=\"$0\"
elif eval '[[ -n \${.sh.file} ]]' 2>/dev/null; then
    eval 'this_script=\${.sh.file}'
else
    echo 1>&2 \"Unsupported shell. Please use bash, dash, ksh93 or zsh.\"
    exit 2
fi

export AMBERHOME=$(cd \"$(dirname \"$this_script\")\"; pwd)
export PATH=\"\${AMBERHOME}/bin:${MINICONDA_PATH_PART}\${PATH}\"
export ${LIB_PATH_VAR}=\"$LD_LIBRARY_PATH:$AMBERHOME/lib\"") 
	
	#Since CMake sets libraries' rpath, you'd think you wouldn't need to set LD_LIBRARY_PATH
	# however, you're forgetting about the nab wrapper, which builds its own executables and isn't smart enough to deal with the rpath.
	
	# following block from http://serverfault.com/questions/139285/tcsh-path-of-sourced-file
	file(WRITE ${SOURCE_FILE_CSH} "# Source this script to add the variables necessary to use AMBER to your shell.
set DUS = ( $_ ) #DUS: Dollar UnderScore
set DNU = $0:q   #DNU: Dollar NUll
if (( $#DUS > 1 )) then
if (\"\${DUS[1]}\" == 'source' || \"$DNU:t\" == 'tcsh' || \"$DNU:t\" == 'csh') then
set DNU = \${DUS[2]:q}
endif
endif

setenv PATH \"\${AMBERHOME}/bin:${MINICONDA_PATH_PART}\${PATH}\"
setenv LD_LIBRARY_PATH \"\${LD_LIBRARY_PATH}:\${AMBERHOME}/\"")
	
	#add the python path setting argument
	if(${BUILD_PYTHON} AND ("${PYTHON_INSTALL}" STREQUAL LOCAL))
	file(APPEND ${SOURCE_FILE_SH} "
	
# Add location of Amber Python modules to default Python search path
if [ -z \"\$PYTHONPATH\" ]; then
	export PYTHONPATH=\"\${AMBERHOME}/lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages\"
else
	export PYTHONPATH=\"\${AMBERHOME}/lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages:\${PYTHONPATH}\"
fi")
		
		file(APPEND ${SOURCE_FILE_CSH} "

# Add location of Amber Python modules to default Python search path
if( ! (\$?PYTHONPATH) ) then
	setenv PYTHONPATH \"\${AMBERHOME}/lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages\"
else
	setenv PYTHONPATH \"\${AMBERHOME}/lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages:\${PYTHONPATH}\"
endif")
	endif()
	
	
	#add the FEW perl module path
	if(BUILD_PERL)
		file(APPEND ${SOURCE_FILE_SH} "

# Add location of Amber Perl modules to Perl search path
if [ -z \"\$PERL5LIB\" ]; then
	export PERL5LIB=\"\${AMBERHOME}/${PERL_MODULE_DIR}\"
else
	export PERL5LIB=\"\${AMBERHOME}/${PERL_MODULE_DIR}:\${PERL5LIB}\"
fi")
	
	file(APPEND ${SOURCE_FILE_CSH} "

# Add location of Amber Perl modules to Perl search path
if( ! (\$?PERL5LIB\) ) then
	setenv PERL5LIB \"\${AMBERHOME}/${PERL_MODULE_DIR}\"
else
	setenv PERL5LIB \"\${AMBERHOME}/${PERL_MODULE_DIR}:\${PERL5LIB}\"
endif")
	endif()
	
	
	#put the scripts on the root dir of the install prefix
	install(PROGRAMS ${SOURCE_FILE_SH} ${SOURCE_FILE_CSH} ${CMAKE_SOURCE_DIR}/cmake-packaging/amber-interactive.sh DESTINATION ".")
endif()
