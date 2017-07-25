if(POLICY CMP0018)
	#enable PROPERTY POSITION_INDEPENDENT_CODE
	cmake_policy(SET CMP0018 NEW)
endif()

if(POLICY CMP0025)
	#report OS X version of Clang as regular clang instead of "AppleClang"
	cmake_policy(SET CMP0025 OLD)
endif()

if(POLICY CMP0026)
	#enable deprecated LOCATION property.  Used for pytraj build workaround.
	cmake_policy(SET CMP0026 OLD)
endif()

if(POLICY CMP0056)
	#pass linker flags to compile tests
	cmake_policy(SET CMP0056 NEW)
endif()

if(POLICY CMP0058)
	#Spoof Ninja dependencies that don't exist in case they are custom command byproducts
	# We would actually like to set this to the new behavior, but it doesn't exist in CMake 3.1
	cmake_policy(SET CMP0058 OLD)
endif()

if(POLICY CMP0065)
	#do not export executable symbols by default
	cmake_policy(SET CMP0065 NEW)
endif()
