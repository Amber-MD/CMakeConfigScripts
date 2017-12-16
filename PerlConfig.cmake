# Configuration file for Perl and the Amber programs that use it.
# Must be included after ExternalLibs.cmake

find_package(Perl)

if(WIN32)
	#On Windows, MakeMaker makefiles require nmake or dmake.  Weird, I know.
	find_program(PERL_MAKE NAMES dmake DOC "Make program to use for building perl programs.  Must be dmake.  GNU make does not work.  Yes, I know that's idiotic, complain to the people who make Module::Install")
else()
	find_program(PERL_MAKE NAMES make DOC "Make program to use for building perl programs.  Should be GNU Make.")
endif()

test(BUILD_PERL_DEFAULT PERL_FOUND)

option(BUILD_PERL "Build the tools which use Perl." ${BUILD_PERL_DEFAULT})

if(PERL_MAKE)
	set(HAVE_PERL_MAKE TRUE)
else()
	set(HAVE_PERL_MAKE FALSE)
endif()

#We have to guess the install directory used by the install script
if(BUILD_PERL)
	
	#relative to install prefix, must NOT begin with a slash
	set(PERL_MODULE_DIR "lib/perl" CACHE STRING "Path relative to install prefix where perl modules are installed.  This path gets added to the startup script") 
	
	message(STATUS "Perl modules well be installed to AMBERHOME/${PERL_MODULE_DIR}")
endif()

