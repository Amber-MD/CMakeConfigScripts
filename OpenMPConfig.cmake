#Cmake config file for OpenMP
option(OPENMP "Use OpenMP for shared-memory parallelization." FALSE)

if(OPENMP)
	find_package(OpenMPFixed)

	if(DEFINED OPENMP_FOUND AND NOT OPENMP_FOUND)
		message(FATAL_ERROR "You requested OpenMP support, but your compiler doesn't seem to support OpenMP.  Please set OPENMP to FALSE, or switch to a compiler that supports it.")
	endif()
else()
	#set these flags to empty string so that they can be used all the time without having to worry about wihether OpenMP is enabled
	set(OpenMP_C_FLAGS "")
	set(OpenMP_CXX_FLAGS "")
	set(OpenMP_Fortran_FLAGS "")
endif()

function(enable_openmp TARGET LANGUAGE)
	if(OPENMP)
		#force the linker language
		set_property(TARGET ${TARGET} PROPERTY LINKER_LANGUAGE ${LANGUAGE})
		
		target_compile_options(${TARGET} PRIVATE ${OpenMP_${LANGUAGE}_FLAGS})
		
		set_property(TARGET ${TARGET} APPEND_STRING PROPERTY LINK_FLAGS " ${OpenMP_${LANGUAGE}_FLAGS}")
		
		set_property(TARGET ${TARGET} APPEND PROPERTY INTERFACE_LINK_LIBRARIES ${OpenMP_${LANGUAGE}_FLAGS})
	endif()
endfunction(enable_openmp)