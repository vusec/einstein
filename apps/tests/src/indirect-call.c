#include "tests_common.h"

void func0(void) { printf("Executing func0!\n"); }
void func1(void) { printf("Executing func1!\n"); }
void func2(void) { printf("Executing func2!\n"); }
void func3(void) { printf("Executing func3!\n"); }
void (*jump_table[4])(void) = { func0, func1, func2, func3 };

int main(int argc, char** argv)
{
	int a = argc%4;

	printf(" a             = %d\n"
	       " jump_table[a] = %p\n"
	       "&a             = %p   <---- Index should have this taint\n"
	       "&jump_table[a] = %p   <---- Code pointer should have this taint\n",
	       a, jump_table[a], &a, &jump_table[a]);
	fflush(stdout);

	__libdft_taint_mem_all();

	// Test indirect call
	void (*fn_ptr)(void) = jump_table[a];
	fn_ptr();

	/*
	printf("%s: Dumping taint for fn_ptr...\n", __FILE__);
	fflush(stdout);
	__libdft_taint_dump(&fn_ptr);
	*/

	return 0;
}
