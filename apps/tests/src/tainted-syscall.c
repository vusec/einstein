#include "tests_common.h"

#ifndef ROOT
#error Please define ROOT
#endif

uint64_t a; // taintable because non-stack
char * filename_robuf = "/foobar"; // the pointer is writable, but the string itself is not (we're using a bad filename because we want execve to fail, then return, and continue the test)
char ** argv_global;
char * filename_txt = ROOT"/apps/tests/build/hello-log";
char * hello_str = "Hello!";

int main(int argc, char** argv)
{
	a = argc%2 + 30;

	/*
	fprintf(stderr,
	       " a             = %lu\n"
	       "&a             = %p   <---- The 3rd syscall argument should have this taint (and should be the only tainted arg)\n",
	       a, &a);
	*/

	char * filename_rwbuf = malloc(32); // writable
	strcpy(filename_rwbuf, filename_robuf);

	char * agt[] = {"/hello", NULL};
	argv_global = agt;

	/*
	fprintf(stderr, "========\n"
	       "*filename_rwbuf (heap)   = %p\n"
	       "a (global)            = %p\n"
	       "*filename_robuf (global) = %p\n"
	       "========\n", filename_rwbuf, &a, filename_robuf);
	*/

	__libdft_taint_mem_all();

	fprintf(stderr, "****** %s:%d: Running 'tainted syscall number' test (will either be shmat or shmctl)...\n", __FILE__, __LINE__);
	asm volatile(
		"movq %0, %%rax;"	// Syscall number = a (tainted)
		"xorq %%rdi, %%rdi;"  	// Args 1--6 = 0 (untainted)
		"xorq %%rsi, %%rsi;"
		"xorq %%rdx, %%rdx;"
		"xorq %%r10, %%r10;"
		"xorq %%r8, %%r8;"
		"xorq %%r9, %%r9;"
		"syscall;"
		:: "r" (a)
		: "rax", "rdi", "rsi", "rdx", "r10", "r8", "r9", "memory");

	fprintf(stderr, "****** %s:%d: Running 'mmap with tainted dword' test...\n", __FILE__, __LINE__);
	syscall(SYS_mmap, 0, 0, a, 0, 0, 0);

	// Note: Because the cmdsvr is being preloaded, Einstein should remove the env vars from the actual execve() call. Otherwise, the cmdsvr would fail.
	fprintf(stderr, "****** %s:%d: Running 'execve with tainted filename pointer' test (and the preloaded cmdsvr)...\n", __FILE__, __LINE__);
	char *const argvp_ro[] = {filename_robuf, NULL};
	char *const envp_ldpreload[]  = {"PIN_APP_LD_PRELOAD="ROOT"/bin/libdbt-cmdsvr.so", "LD_PRELOAD="ROOT"/bin/libdbt-cmdsvr.so", NULL};
	syscall(SYS_execve, filename_robuf, argvp_ro, envp_ldpreload);

	fprintf(stderr, "****** %s:%d: Running 'execveat with tainted filename string (on the heap)' test...\n", __FILE__, __LINE__);
	char *const argvp_rw[] = {filename_rwbuf, NULL};
	char *const envp_none[]  = {NULL};
	syscall(SYS_execveat, 0, filename_rwbuf, argvp_rw, envp_none, 0);

	fprintf(stderr, "****** %s:%d: Running 'execve with tainted argv' test...\n", __FILE__, __LINE__);
	syscall(SYS_execve, "/hello", argv_global, envp_none);

	fprintf(stderr, "****** %s:%d: Running 'open->write chain' test...\n", __FILE__, __LINE__);
	FILE *fp;
	fp = fopen(filename_txt, "a");
	fprintf(fp, "Here's the string: '%s'!\n", hello_str);
	fclose(fp);
	//int fd = syscall(SYS_openat, AT_FDCWD, filename_txt, O_WRONLY|O_CREAT|O_APPEND, 0666);
	//char * s = "\%\% 500 /\b\b\b\b\b\b\b\bATTACKER SAYS HI\n";
	//size_t l = strlen(s);
	//syscall(SYS_write, fd, s, l);
	//syscall(SYS_close, fd);

	fprintf(stderr, "****** %s:%d: Finished tests.\n\n", __FILE__, __LINE__);

	return 0;
}
