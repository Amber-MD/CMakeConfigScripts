#This file contains the logic for deciding which tools (subdirectories in AmberTools) should get built

# Must be included after PythonConfig.cmake and GUIConfig.cmake

#First we list all of the tools, in the correct order. 
#The order IS important, as targets used by one tool have to be added first, 
#and CMake executes these sequentially.


# There are many, many reasons that you would want a tool not to build, and in some cases more than one can occur at the same time
# For that reason, and because order matters, we use a blacklist model for deciding what tools to build.
# We start with all of them enabled (except the ones not in release builds), and pare down this list for various reasons in the logic below.
set(AMBER_TOOLS 
#3rd party programs: see 3rdPartyTools.cmake
#	utility routines and libraries:
gbnsr6
lib
cifparse

#	old Amber programs
addles
sander
nmr_aux
nmode

#	antechamber:
antechamber
sqm

#   miscellaneous:
reduce
sebomd
emil
ndiff-2.00

#	cpptraj:
cpptraj

#   nab:
pbsa
sff
rism
nab
nabc
nss
etc

#   mdgx:
mdgx

#   xtalutil:
xtalutil

#   saxs and saxs_md:
saxs

#	mm_pbsa
mm_pbsa

#	paramfit
paramfit


#	FEW
FEW

#	amberlite
amberlite

#	cphstats and cestats
cphstats

#	quick
quick

#	nfe-umbrella-slice
nfe-umbrella-slice

#   leap
leap

#   python programs
parmed
mmpbsa_py
pymsmt
pysander
pytraj
pymdgx
pdb4amber)

if(NOT AMBER_RELEASE)
	# these tools are in the git version of amber, but not in the released source
	list(APPEND AMBER_TOOLS 
		chamber
		ptraj
		mtkpp)
endif()

# save an unaltered copy for disable_all_tools_except()
set(ALL_TOOLS ${AMBER_TOOLS})

set(REMOVED_TOOLS "")
set(REMOVED_TOOL_REASONS "")

#Macro which disables a tool 
macro(disable_tool TOOL REASON)
	
	list(FIND AMBER_TOOLS ${TOOL} STILL_IN_TOOLS)
	list(FIND REMOVED_TOOLS ${TOOL} ALREADY_REMOVED)
	
	
	if(ALREADY_REMOVED EQUAL -1) #If we've already removed the tool, don't do anything
		
		# if the tool is present in neither list, then it means it's a tool that isn't included in the release build and was disabled
		if(NOT STILL_IN_TOOLS EQUAL -1)
			
			list(REMOVE_ITEM AMBER_TOOLS ${TOOL})
			
			list(APPEND REMOVED_TOOLS ${TOOL})
			list(APPEND REMOVED_TOOL_REASONS ${REASON})
		endif()
	endif()
endmacro(disable_tool)

#Macro which disables a list of tools for the same reason
macro(disable_tools REASON) # TOOLS...
	foreach(TOOL ${ARGN})
		disable_tool(${TOOL} ${REASON})
	endforeach()
endmacro(disable_tools)

#Disable all tools except the ones provided for REASON
macro(disable_all_tools_except REASON) # TOOLS...
	foreach(TOOL ${ALL_TOOLS})
		list_contains(KEEP_THIS_TOOL ${TOOL} ${ARGN})
		if(NOT KEEP_THIS_TOOL)
			disable_tool(${TOOL} ${REASON})
		endif()
	endforeach()
endmacro(disable_all_tools_except)

# set the dependencies of a tool
# if one of its dependencies is disabled, then TOOL will also be disabled.
# NOTE: circular dependencies are OK (for example, SANDER and PBSA depend on each other)
macro(tool_depends TOOL) #ARGN: other tools that TOOL depends on
	if(DEFINED TOOL_DEPENDENCIES_${TOOL})
		list(APPEND TOOL_DEPENDENCIES_${TOOL} ${ARGN})
	else()
		set(TOOL_DEPENDENCIES_${TOOL} ${ARGN})
	endif()

endmacro(tool_depends)


# --------------------------------------------------------------------
# tool dependencies (manually determined by looking through every single CMake script)
# --------------------------------------------------------------------
tool_depends(addles lib)
tool_depends(amberlite nab)
tool_depends(antechamber cifparse)
tool_depends(etc nab)
tool_depends(mm_pbsa nab lib)
tool_depends(mmpbsa_py nab lib)
tool_depends(nab sff pbsa cifparse)
tool_depends(nmode lib)
tool_depends(nmr_aux cifparse lib)
tool_depends(nss nab)
tool_depends(pbsa sander lib)
tool_depends(pymdgx mdgx)
tool_depends(pysander sander)
tool_depends(pytraj cpptraj)
tool_depends(quick sqm)
tool_depends(rism nab lib)
tool_depends(sander sqm pbsa sebomd emil lib)
tool_depends(sebomd sander lib)
tool_depends(sff pbsa)
tool_depends(sqm sff lib)

# extra dependencies if FFT is enabled
if(USE_FFT)
	tool_depends(nab rism)
	tool_depends(sff rism)
	tool_depends(sander rism)
	tool_depends(sebomd rism)
endif()
# --------------------------------------------------------------------
# Now, the logic for deciding whether to use them
# --------------------------------------------------------------------

# FFT programs
if(USE_FFT)
	if(${CMAKE_C_COMPILER_ID} STREQUAL PGI)

		# RISM and PBSA FFT solver require ISO_C_BINDING support.
		if(${CMAKE_C_COMPILER_VERSION} VERSION_LESS 9.0.4)
			message(FATAL_ERROR "RISM and PBSA FFT solver require PGI compiler version 9.0-4 or higher. Please disable USE_FFT.")
		endif()
	elseif(${CMAKE_C_COMPILER_ID} STREQUAL Cray) 
		message(FATAL_ERROR "RISM and PBSA FFT solver currently not built with cray compilers.  Please disable USE_FFT.")
	endif()
else()
	disable_tools("Requires FFTW, but USE_FFT is disabled." rism mdgx)
endif()

#Python programs (controlled by BUILD_PYTHON option in PythonConfig.cmake)
if(NOT BUILD_PYTHON)
	disable_tools("Python programs are disabled" pysander pytraj pysmt mmpbsa_py parmed pymdgx)
endif()

if(STATIC)
	disable_tools("Python programs cannot link to static libsander" pysander pytraj)
endif()

if(MPI AND mpi4py_DISABLED)
	disable_tool(mmpbsa_py "mmpbsa_py requires mpi4py when MPI is enabled")
endif()


# Perl programs
if(NOT BUILD_PERL)
	disable_tools("Perl programs are disabled" FEW mm_pbsa)
endif()

if(perlmol_DISABLED)
	disable_tool(FEW "FEW requires perlmol")
endif()

#deprecated programs
option(BUILD_DEPRECATED "Build outdated and deprecated tools, such as ptraj" FALSE)
if(NOT BUILD_DEPRECATED)
	disable_tools("Deprecated tools are disabled" ptraj mtkpp)
endif()

# in-development programs
option(BUILD_INDEV "Build Amber programs which are still being developed.  These probably contain bugs, and may not be finished.")
if(NOT BUILD_INDEV)
	disable_tools("In-development programs are disabled." gleap quick pymdgx)
endif()

if(NOT BUILD_SANDER_API)
	disable_tool(pysander "The Sander API is disabled")
endif()

if(CROSSCOMPILE)
	disable_tools("Python programs with native libraries can't be cross-compiled (see Amber bug #337)" pysander pytraj pymdgx parmed)
endif()

# host tools
if(USE_HOST_TOOLS)
	disable_tool(byacc "Using host tools version")
endif()

# PGI won't compile MTK++; see bug 219.
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL PGI)
	disable_tool(mtkpp "Not compatible with the PGI C++ compiler.")
endif()

# ...neither will AppleClang >= 8.0.  That Eigen library seems to be murder on compilers.
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL AppleClang AND ("${CMAKE_CXX_COMPILER_VERSION}" VERSION_GREATER 8.0 OR "${CMAKE_CXX_COMPILER_VERSION}" VERSION_EQUAL 8.0))

	disable_tool(mtkpp "Not compatible with AppleClang >= 8.0.")
endif()

if(MINGW)
	disable_tool(pytraj "pytraj is not currently supported with MinGW. It must be built with MSVC.")
endif() 

# --------------------------------------------------------------------
# Disable certain sets of programs due to the build type
# --------------------------------------------------------------------
if(CRAY)
	# In cray parallel modes, almost all tools are disabled.
	if(MPI)
		disable_all_tools_except("Not supported on Cray in MPI mode" etc sff cpptraj cifparse mdgx nab rism parmed mmpbsa_py)
	elseif(OPENMP)
		disable_all_tools_except("Not supported on Cray in OpenMP mode" sff cifparse nab rism cpptraj pytraj saxs paramfit)

	else()
		disable_tools("Not supported on Cray in serial mode"
			pbsa
			gbnsr6
			sander
			nmr_aux
			nss
			etc
			mmpbsa
			amberlite
			quick)
	endif()
endif()

#------------------------------------------------------------------------------
#  User Config
#------------------------------------------------------------------------------
set(DISABLE_TOOLS "" CACHE STRING "Tools to not build.  Accepts a semicolon-seperated list of directories in AmberTools/src.")
disable_tools("Disabled by user" ${DISABLE_TOOLS})


# --------------------------------------------------------------------
# Disable tools whose dependencies have been disabled
# --------------------------------------------------------------------

# we have to go through this a couple times.  Lets say A depends on B, and B depends on C.
# Early on, A checks if B is there, and it is, so A stays enabled.  Later, B checks if C is there, and it isn't, so
# it disables itself. However, now A is enabled when it shouldn't be.
# There are probably more sophisticated ways to solve this but they'd be difficult to implement in CMake

# hopefully 3 iterations is enough
foreach(ITERATION RANGE 0 2)
	foreach(TOOL ${AMBER_TOOLS})
		
		foreach(DEPENDENCY ${TOOL_DEPENDENCIES_${TOOL}})
			list_contains(DEPEND_ENABLED ${DEPENDENCY} ${AMBER_TOOLS})
			
			#message("${TOOL} depends on ${DEPENDENCY}")
			
			if(NOT DEPEND_ENABLED)
				disable_tool(${TOOL} "Its dependency ${DEPENDENCY} is disabled.")
			endif()
		endforeach()
	endforeach()
endforeach()
