#ifndef TEST_COMMON_H
#define TEST_COMMON_H

#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#include <sys/mman.h>
#include <sys/syscall.h>
#include <sys/types.h>

#include "libdft_cmd.h"

void wait_for_signal(void) {
	int sig;
	sigset_t signal_set;
	sigemptyset(&signal_set);
	sigaddset(&signal_set, SIGUSR1);
	if (sigwait(&signal_set, &sig) != 0) {
		fprintf(stderr, "%s: Error waiting for signal.\n", __FILE__);
		exit(1);
	}
}

#endif
