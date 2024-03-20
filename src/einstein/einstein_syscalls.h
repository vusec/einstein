#ifndef EINSTEIN_SYSCALLS_H
#define EINSTEIN_SYSCALLS_H

#include "einstein_common.h"

extern bool hook_writes;

typedef struct {
  string name;
  bool (*arg_is_tainted)(syscall_ctx_t *ctx);
  string (*get_details)(syscall_ctx_t *ctx);
  void (*rewrite_init)(string type, size_t ptr_depth, size_t syscall_arg_num, uint8_t * address, size_t size);
  bool (*rewrite_check)(syscall_ctx_t *ctx, size_t arg_num);
} einstein_syscall_t;

extern einstein_syscall_t einstein_syscalls[SYSCALL_MAX];

void fd_create(int fd, unsigned long long this_report_num, syscall_ctx_t *ctx);
void fd_close(int fd);

bool is_syscall_fd_creator(int nr);
bool is_syscall_sec_sensitive(int nr);

void einstein_syscalls_init(void);

#endif