#ifndef EINSTEIN_SYSCALLS_INTERNAL_H
#define EINSTEIN_SYSCALLS_INTERNAL_H

#include "einstein_common.h"
#include "einstein_syscalls.h"

void fd_create_internal(int fd, unsigned long long this_report_num, syscall_ctx_t *ctx);
void fd_close_internal(int fd);

static inline string details_none() { return "{\"type\": \"none\"}"; }
string details_fd(ADDRINT fd, tagqarr_t fd_taint);
string details_dword(ADDRINT val, tagqarr_t val_taint);
string details_qword(ADDRINT val, tagqarr_t val_taint);
string details_vptr(void * ptr, tagqarr_t ptr_taint, size_t len);
string details_iovec(const struct iovec *iov, tagqarr_t ptr_taint, int iovcnt);
string details_ppchar(char ** pptr, tagqarr_t pptr_taint);
string details_sockaddr(const struct sockaddr * addr, tagqarr_t addr_taint, socklen_t addrlen);

bool is_tainted_dword(tagqarr_t val_taint);
bool is_tainted_qword(tagqarr_t val_taint);
bool is_tainted_vptr(void * ptr, tagqarr_t ptr_taint, size_t len);
bool is_tainted_iovec(const struct iovec *iov, tagqarr_t ptr_taint, int iovcnt);
bool is_tainted_ppchar(char ** pptr, tagqarr_t pptr_taint);
bool is_tainted_sockaddr(const struct sockaddr * addr, tagqarr_t addr_taint, socklen_t addrlen);

bool is_controllable_fd(int fd, tagqarr_t fd_taint);
bool is_controllable_sockfd(int sockfd, tagqarr_t fd_taint);

#endif