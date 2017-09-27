if(POLICY CMP0018)
	#NEW: enable PROPERTY POSITION_INDEPENDENT_CODE
	cmake_policy(SET CMP0018 NEW)
endif()

if(POLICY CMP0025)
	#NEW: report OS X version of Clang as "AppleClang"
	cmake_policy(SET CMP0025 NEW)
endif()

if(POLICY CMP0026)
	#NEW: disable deprecated LOCATION property. 
	cmake_policy(SET CMP0026 NEW)
endif()

if(POLICY CMP0042)
	#NEW: set TARGET PROPERTY MACOSX_RPATH to on by default
	cmake_policy(SET CMP0042 NEW)
endif()

if(POLICY CMP0053)
	#NEW: use stricter and safer variable name rules
	cmake_policy(SET CMP0053 NEW)
endif()

if(POLICY CMP0056)
	#pass linker flags to compile tests
	cmake_policy(SET CMP0056 NEW)
endif()

if(POLICY CMP0058)
	#Spoof Ninja dependencies that don't exist in case they are custom command byproducts
	# We would actually like to set this to the new behavior, but it doesn't exist in CMake 3.1 and we want consistency
	cmake_policy(SET CMP0058 OLD)
endif()

if(POLICY CMP0065)
	#do not export executable symbols by default
	cmake_policy(SET CMP0065 NEW)
endif()
