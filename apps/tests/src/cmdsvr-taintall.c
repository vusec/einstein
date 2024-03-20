#include "tests_common.h"

int main(int argc, char** argv)
{
	int a = argc, b = argc%2, c = argc/2;

	printf("%s: Waiting for 'taintall' command...\n", __FILE__);
	wait_for_signal();

	// Test taint propagation
	c = a+b;

	// Dump
	printf("%s: [calculated] c @%p = a @%p + b @%p\n", __FILE__, &c, &a, &b);
	__libdft_taint_dump(&a);
	__libdft_taint_dump(&b);
	__libdft_taint_dump(&c);

	/*
	 * Sample expected output:
	 * [calculated] c @0x7fffffffe1f8 = a @0x7fffffffe1f0 + b @0x7fffffffe1f4
	 * [taint_dump] addr=0x7fffffffe1f0, tags={0x7fffffffe1f0}
	 * [taint_dump] addr=0x7fffffffe1f4, tags={0x7fffffffe1f4}
	 * [taint_dump] addr=0x7fffffffe1f8, tags={0x7fffffffe1f4, 0x7fffffffe1f0}
	 */

	return 0;
}
