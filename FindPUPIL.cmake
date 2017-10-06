# - Find PUPIL
# Find the native PUPIL libraries
# NOTE: the Java link library is required to link with PUPIL, so this module will find it as well
#
# This module defines
#
#  PUPIL_LIBRARIES, the libraries needed to use PUPIL.
#  PUPIL_FOUND, If false, do not try to use PUPIL.


include(FindPackageHandleStandardArgs)



find_library(PUPIL_MAIN_LIB PUPIL NO_SYSTEM_ENVIRONMENT_PATH)
find_library(PUPIL_BLIND_LIB PUPILBlind NO_SYSTEM_ENVIRONMENT_PATH)
find_library(PUPIL_TIME_LIB PUPILTime NO_SYSTEM_ENVIRONMENT_PATH)

find_package(JNIFixed)

set(PUPIL_LIBRARIES ${PUPIL_MAIN_LIB} ${PUPIL_BLIND_LIB} ${PUPIL_TIME_LIB} ${JNI_LIBRARIES})

if(NOT JNI_FOUND)
	set(FIND_PUPIL_FAILURE_MESSAGE "Could not find the Java development libraries, so PUPIL can't be used.")
else()
	set(FIND_PUPIL_FAILURE_MESSAGE "Could not find some or all of the four PUPIL libraries. Please set PUPIL_MAIN_LIB, PUPIL_BLIND_LIB, and
PUPIL_TIME_LIB to point to the correct libraries")
endif()

find_package_handle_standard_args(PUPIL ${FIND_PUPIL_FAILURE_MESSAGE} PUPIL_MAIN_LIB PUPIL_BLIND_LIB PUPIL_TIME_LIB JNI_LIBRARIES)