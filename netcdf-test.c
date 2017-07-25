#include <stdio.h>
#include <netcdf.h>

int main()
{
	// NOTE: newlines in this file will get parsed by CMake, so they have to be double-backslashed.
	printf("%s\\n",nc_strerror(0));
	printf("Testing\\n");
	return 0;
}