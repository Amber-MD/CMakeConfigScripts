#Amber: Taken from https://sourceforge.net/p/k3d/k3d/ci/8ad0946f3dba84c812982f1054e57d0c02122b21/tree/cmake/modules/FindGtkGLExt.cmake

SET(GTKGLEXT_FOUND 0)

######################################################################
# Posix specific configuration

IF(UNIX)
	INCLUDE(FindPkgConfig)
	PKG_CHECK_MODULES(GTKGLEXT gtkglext-1.0)

ENDIF(UNIX)

######################################################################
# Win32 specific configuration

IF(WIN32)
	# Configure gtkglext ...
	SET(GDKGLEXT_LIB gdkglext-win32-1.0 CACHE STRING "")
	MARK_AS_ADVANCED(GDKGLEXT_LIB)

	SET(GTKGLEXT_LIB gtkglext-win32-1.0 CACHE STRING "")
	MARK_AS_ADVANCED(GTKGLEXT_LIB)

	FIND_PATH(GTKGLEXT_CONFIG_INCLUDE_DIR gdkglext-config.h
		c:/gtk/lib/gtkglext-1.0/include
		${K3D_GTK_DIR}/lib/gtkglext-1.0/include 
		DOC "Directory where the gtkglext config file is located"
		)
	MARK_AS_ADVANCED(GTKGLEXT_CONFIG_INCLUDE_DIR)

	FIND_PATH(GTKGLEXT_INCLUDE_DIR gtk
		c:/gtk/include/gtkglext-1.0
		DOC "Directory where the gtkglext header files are located"
		)
	MARK_AS_ADVANCED(GTKGLEXT_INCLUDE_DIR)

	SET(GTKGLEXT_INCLUDE_DIRS
		${GTKGLEXT_CONFIG_INCLUDE_DIR}
		${GTKGLEXT_INCLUDE_DIR}
		)

	SET(GTKGLEXT_LIBRARIES
		${GDKGLEXT_LIB}
		${GTKGLEXT_LIB}
		)

	SET(GTKGLEXT_FOUND 1)

ENDIF(WIN32)

