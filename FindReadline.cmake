# from http://websvn.kde.org/trunk/KDE/kdeedu/cmake/modules/FindReadline.cmake
# http://websvn.kde.org/trunk/KDE/kdeedu/cmake/modules/COPYING-CMAKE-SCRIPTS
# --> BSD licensed
#
# Modified for AMBER
#
# GNU Readline library finder.
#
# Variables: 
#   READLINE_INCLUDE_DIR - directory containing readline/readline.h

find_path(READLINE_INCLUDE_DIR NAMES readline/readline.h DOC "directory containing readline/readline.h")

find_library(READLINE_LIBRARY NAMES readline DOC "Path to readline library.")

if(EXISTS "${READLINE_LIBRARY}")
	# now check if the library we found actually works (certain versions of Anaconda ship with a broken 
	# libreadline.so that uses functions from libtinfo, but does not declare a dynamic dependency on said library.)
	set(CMAKE_REQUIRED_LIBRARIES ${READLINE_LIBRARY})
	check_function_exists(rl_initialize READLINE_IS_LINKABLE)
	mark_as_advanced(READLINE_IS_LINKABLE)
else()
	set(READLINE_IS_LINKABLE FALSE)
endif()

mark_as_advanced(READLINE_INCLUDE_DIR READLINE_LIBRARY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Readline DEFAULT_MSG READLINE_INCLUDE_DIR READLINE_LIBRARY READLINE_IS_LINKABLE)
