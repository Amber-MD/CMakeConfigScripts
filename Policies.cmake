if(POLICY CMP0003)
	#NEW: always link libraries by full path
	cmake_policy(SET CMP0003 NEW)
endif()

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
	#OLD: Spoof Ninja dependencies that don't exist in case they are custom command byproducts
	# We would actually like to set this to the new behavior, but it doesn't exist in CMake 3.1 and we want consistency
	cmake_policy(SET CMP0058 OLD)
endif()

if(POLICY CMP0060)
	#NEW: Link all libraries by full path regardless of implicit dirs
	cmake_policy(SET CMP0060 NEW)
endif()


if(POLICY CMP0065)
	#NEW: do not export executable symbols by default
	cmake_policy(SET CMP0065 NEW)
endif()

if(POLICY CMP0066)
	#NEW: pass CMAKE_<lang>_FLAGS_<config> to try_compile() statements
	cmake_policy(SET CMP0066 NEW)
endif()

if(POLICY CMP0073)
	#NEW: don't generate xxx_LIB_DEPENDS cache entries (which screw up the build when switching between bundled and external libraries)
	cmake_policy(SET CMP0073 NEW)
endif()

