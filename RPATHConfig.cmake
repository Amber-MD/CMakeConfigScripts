# Configures the RPATH.
# Must be included after CompilerOptions.cmake


if(TARGET_OSX)
	# recent macOS versions have disabled DYLD_LIBRARY_PATH for secutiry reasons.
	# so, we set the RPATH to '../lib', which is interpereted relative the the executable or library's current location
	
	set(CMAKE_INSTALL_RPATH "../${LIBDIR}")
	set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
else()
	
	# set the RPATH to the absolute install dir.  This enables using many Amber programs without sourcign amber.sh.
	# If you do move the install tree, then amber.sh will still set LD_LIBRARY_PATH, and it'll will work fine once you've sourced it.
	set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${LIBDIR}")
	set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
endif()