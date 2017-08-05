# This script handles the parts of the Amber CMake init that must happen AFTER the enable_language() command,
# because files included by this use compile tests

# if the target doesn't support import libraries, CMAKE_IMPORT_LIBRARY_SUFFIX is set to an empty string, which is a problem for us.
# we can only do this test after the enable_language() statement
if(NOT DEFINED CMAKE_IMPORT_LIBRARY_SUFFIX)
	set(TARGET_SUPPORTS_IMPORT_LIBRARIES FALSE)
elseif("${CMAKE_IMPORT_LIBRARY_SUFFIX}" STREQUAL "")
	set(TARGET_SUPPORTS_IMPORT_LIBRARIES FALSE)
else()
	set(TARGET_SUPPORTS_IMPORT_LIBRARIES TRUE)
endif()

# standard library and should-be-in-the-standard-library includes
# --------------------------------------------------------------------

include(TargetArch)
include(ExternalProject)
include(CheckFunctionExists)
include(CheckFortranFunctionExists)
include(CheckIncludeFile)
include(CheckIncludeFileCXX)
include(CheckCSourceRuns)
include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)
include(CheckLinkerFlag)
include(CheckFortranSourceRuns)
include(CheckSymbolExists)
include(CheckConstantExists)
include(CheckLibraryExists)
include(CheckPythonPackage)
include(CheckTypeSize)
include(LibraryTracking)
include(DownloadHttps)
include(Replace)
include(BuildReport)
include(ConfigModuleDirs)
include(ApplyOptimizationDeclarations)
include(CompilationOptions)
include(VerifyCompilerConfig)
