#Function which (a) sets the module output directory for a target, and (b) includes other module directories.
#preserves the include directories already set on the target, adding them at the end of the list

#created mainly because the syntax for doing this is WAY too verbose
function(config_module_dirs TARGETNAME TARGET_MODULE_DIR) #3rd optional argument: extra module include directories
	#add all of the passed module directories
	set(INCLUDE_DIRS ${TARGET_MODULE_DIR} ${ARGN})
	
	# get old include directories
	get_property(PREV_INC_DIRS TARGET ${TARGETNAME} PROPERTY INCLUDE_DIRECTORIES)
	get_property(PREV_INT_INC_DIRS TARGET ${TARGETNAME} PROPERTY INCLUDE_DIRECTORIES)
	
	# prepend module dir to include dirs
	set_property(TARGET ${TARGETNAME} PROPERTY Fortran_MODULE_DIRECTORY ${TARGET_MODULE_DIR})
	set_property(TARGET ${TARGETNAME} PROPERTY INCLUDE_DIRECTORIES ${INCLUDE_DIRS} ${PREV_INC_DIRS})
	set_property(TARGET ${TARGETNAME} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${INCLUDE_DIRS} ${PREV_INC_DIRS})
	
endfunction()
	

