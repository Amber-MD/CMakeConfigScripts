#CUDA configuration script for AMBER

# With CMake 3.7, FindCUDA.cmake crashes when crosscompiling.

if(CROSSCOMPILE)
	message(STATUS "CUDA disabled when crosscompiling.")
	set(CUDA FALSE)
else()

	#first, find CUDA.
	find_package(CUDA)
	option(CUDA "Build ${PROJECT_NAME} with CUDA GPU acceleration support." FALSE)
	
	if(CUDA AND NOT CUDA_FOUND)
		message(FATAL_ERROR "You turned on CUDA, but it was not found.  Please set the CUDA_TOOLKIT_ROOT_DIR option to your CUDA install directory.")
	endif()
	
	if(CUDA)
		#Note at present we do not include SM3.5 or SM3.7 since they sometimes show performance
		#regressions over just using SM3.0.
		#SM6.2 = ??? 
		set(SM62FLAGS "-gencode arch=compute_62,code=sm_62")
		#SM6.1 = GP106 = GTX-1070, GP104 = GTX-1080, GP102 = Titan-X[P]
		set(SM61FLAGS "-gencode arch=compute_61,code=sm_61")
		#SM6.0 = GP100 / P100 = DGX-1
		set(SM60FLAGS "-gencode arch=compute_60,code=sm_60")
		#SM5.3 = GM200 [Grid] = M60, M40?
		set(SM53FLAGS "-gencode arch=compute_53,code=sm_53")
		#SM5.2 = GM200 = GTX-Titan-X, M6000 etc.
		set(SM52FLAGS "-gencode arch=compute_52,code=sm_52")
		#SM5.0 = GM204 = GTX980, 970 etc
		set(SM50FLAGS "-gencode arch=compute_50,code=sm_50")
		#SM3.7 = GK210 = K80
		set(SM37FLAGS "-gencode arch=compute_37,code=sm_37")
		#SM3.5 = GK110 + 110B = K20, K20X, K40, GTX780, GTX-Titan, GTX-Titan-Black, GTX-Titan-Z
		set(SM35FLAGS "-gencode arch=compute_35,code=sm_35")
		#SM3.0 = GK104 = K10, GTX680, 690 etc.
		set(SM30FLAGS "-gencode arch=compute_30,code=sm_30")
	
		message(STATUS "CUDA version ${CUDA_VERSION} detected")
		
		if(${CUDA_VERSION} VERSION_EQUAL 7.5)
			message("Configuring CUDA for SM3.0, SM5.0, SM5.2 and SM5.3")
			message("BE AWARE: CUDA 7.5 does not support GTX-1080, DGX-1 or other Pascal based GPUs.")
		  	list(APPEND CUDA_NVCC_FLAGS ${SM30FLAGS} ${SM50FLAGS} ${SM52FLAGS} ${SM53FLAGS})
		elseif((${CUDA_VERSION} VERSION_EQUAL 8.0) OR (${CUDA_VERSION} VERSION_GREATER 8.0))
			message("Configuring CUDA for SM3.0, SM5.0, SM5.2, SM5.3, SM6.0, SM6.1 and SM6.2")
		  	list(APPEND CUDA_NVCC_FLAGS ${SM30FLAGS} ${SM50FLAGS} ${SM52FLAGS} ${SM53FLAGS} ${SM60FLAGS} ${SM61FLAGS} ${SM62FLAGS} -Wno-deprecated-gpu-targets)
		else()
			message(FATAL_ERROR "Error: Unsupported CUDA version. AMBER requires CUDA version >= 7.5.
				Please upgrade your CUDA installation or disable building with CUDA.")
		endif()
		
		set(CUDA_PROPAGATE_HOST_FLAGS FALSE)
		
		#as of 2016 and CMake 3.2, this does not work reliably.
		#set(CUDA_SEPARABLE_COMPILATION TRUE)
		
		#the same CUDA file is used for multiple targets in PMEMD, so turn this off
		set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE FALSE)
				
		# --------------------------------------------------------------------
		# import a couple of CUDA libraries used by PMEMD
		import_libraries(cublas LIBRARIES ${CUDA_CUBLAS_LIBRARIES})
		import_libraries(cufft LIBRARIES ${CUDA_CUFFT_LIBRARIES})
	
		import_library(curand ${CUDA_curand_LIBRARY})
	endif()
endif()