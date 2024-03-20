#include "tests_common.h"

int arr[4] = {1,2,3,4};

int main(int argc, char** argv)
{
	int a = argc%4, out;

	printf(" a      = %d\n"
	       "&a      = %p  <---- Final output should have this taint (i.e., the INDEX), if load pointer propagation is enabled\n"
	       "&arr[a] = %p  <---- Final output should have this taint (i.e., the DATA)\n",
	       a, &a, &arr[a]);
	fflush(stdout);

	__libdft_taint_mem_all();

	// Test load pointer propagation
	out = arr[a];

	__libdft_taint_dump(&out);

	return 0;
}
