# Configuration file for GUI libraries and the programs that use them.

#-----------------------------------
# X for XLeap
#-----------------------------------
find_package(X11)

if((NOT X11_FOUND) AND (${CMAKE_SYSTEM_NAME} STREQUAL Linux))
	message("Couldn't find the X11 development libraries!")
	message("To search for them try the command: locate libXt")
	message("       On new Fedora install the libXt-devel libXext-devel libX11-devel libICE-devel libSM-devel packages.")
	message("       On old Fedora install the xorg-x11-devel package.")
	message("       On RedHat install the XFree86-devel package.")
	message("       On Ubuntu install the xorg-dev and xserver-xorg packages.")
endif()

# It's likely that when crosscompiling, there will not be GUI libraries for the target, and we actually found the build system's libraries.
# So, we disable BUILD_GUI by default.
test(BUILD_GUI_DEFAULT X11_FOUND AND NOT CROSSCOMPILE)

option(BUILD_GUI "Build graphical interfaces to programs.  Currently affects only LEaP" ${BUILD_GUI_DEFAULT})

if(BUILD_GUI AND (NOT M4 OR NOT X11_FOUND))
	message(FATAL_ERROR "Cannot build Xleap without m4 and the X development libraries.  Either install them, or set BUILD_GUI to FALSE")
endif()