#include "tests_common.h"

#define handle_error(msg) do { perror(msg); exit(EXIT_FAILURE); } while (0)

static void * get_ro_page(void)
{
	int pagesize = sysconf(_SC_PAGE_SIZE);
	if (pagesize == -1) handle_error("sysconf");

	// Allocate a buffer aligned on a page boundary; initial protection is PROT_READ | PROT_WRITE
	char * buffer = aligned_alloc(pagesize, pagesize);
	if (buffer == NULL) handle_error("memalign");

	// Making buffer read-only, i.e., PROT_READ
	if (mprotect(buffer, pagesize, PROT_READ) == -1) handle_error("mprotect");

	return buffer;
}

int main(int argc, char** argv)
{
	char * ro_mem = get_ro_page();
	char * rw_mem = malloc(64);

	fprintf(stderr, "non-writable memory  = %p\n", ro_mem);
	fprintf(stderr, "stack memory         = %p\n", &argc);
	fprintf(stderr, "writable heap memory = %p\n", rw_mem);

	__libdft_taint_mem_all();

	fprintf(stderr, "%s: Dumping taint for non-writable memory (it _should not_ have any taint)...\n", __FILE__);
	__libdft_taint_dump(ro_mem);
	fprintf(stderr, "%s: Dumping taint for stack memory (it _should not_ have any taint)...\n", __FILE__);
	__libdft_taint_dump(&argc);
	fprintf(stderr, "%s: Dumping taint for writable heap memory (it _should_ have taint)...\n", __FILE__);
	__libdft_taint_dump(rw_mem);

	return 0;
}
