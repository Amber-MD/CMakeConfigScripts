# File containing the configuration for Host Tools Mode
# Most other configuration files are disabled when this is activated

#set some important configuration variables
set(BUILD_GUI FALSE)

# we don't want the host tools to have different names if MPI is enabled
if(MPI)
	message(FATAL_ERROR "Cannot build host tools with MPI enabled.  Please disable MPI.")
endif()

#we don't need any 3rd party libraries
set(3RDPARTY_SUBDIRS "")

# Tools we need to build: ucpp, byacc, nab2c, and utilMakeHelp
set(AMBER_TOOLS ucpp-1.3 byacc nab leap)

function(print_host_tools_build_report)
	message("**************************************************************************")
	message("Build Report")
	message("Amber is configured to build host tools only.")
	message("")	
		
	message("Build configuration:    ${CMAKE_BUILD_TYPE}")
	message("Install Location:       ${CMAKE_INSTALL_PREFIX}")
	message("")
	
	#------------------------------------------------------------------------------------------
	message("        Compilers:")
	message("           C: ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION} (${CMAKE_C_COMPILER})")
	message("         CXX: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION} (${CMAKE_CXX_COMPILER})")
	message("     Fortran: ${CMAKE_Fortran_COMPILER_ID} ${CMAKE_Fortran_COMPILER_VERSION} (${CMAKE_Fortran_COMPILER})")
	message("")
	message("**************************************************************************")
endfunction(print_host_tools_build_report)