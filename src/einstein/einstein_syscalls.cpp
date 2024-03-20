#include "einstein_common.h"
#include "einstein_utils.h"
#include "einstein_syscalls.h"
#include "einstein_syscalls_internal.h"
#include "einstein_syscalls_unimpl.h"
#include "einstein_rewrite.h"

bool hook_writes = false;

#define SOCKADDR_CANARY() { AF_INET, htons(3434), inet_addr("192.0.2.0"), {0}}

// ==========================================================================================================================================
// ==========================================================================================================================================
// Handlers: Sec-sensitive syscalls

// =====================================================================
// int execve(const char *pathname, char *const argv[], char *const envp[]);
static bool execve_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_tainted_vptr((char*)ctx->arg[0], ctx->arg_taint[0], strlen((char*)ctx->arg[0])+1) ||
      is_tainted_ppchar((char**)ctx->arg[1], ctx->arg_taint[1]) ||
      is_tainted_ppchar((char**)ctx->arg[2], ctx->arg_taint[2]);
}
static string execve_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_vptr((char*)ctx->arg[0], ctx->arg_taint[0], strlen((char*)ctx->arg[0])+1) + ", " +
      details_ppchar((char**)ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_ppchar((char**)ctx->arg[2], ctx->arg_taint[2]) + "]";
}
static void execve_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_buf(type, ptr_depth, address, size, "/tmp/hi", strlen("/tmp/hi")+1);
  else if (arg_num == 1) einstein_rewrite_init_buf(type, ptr_depth, address, size, "/tmp/hi", strlen("/tmp/hi")+1);
  else if (arg_num == 2) einstein_rewrite_init_buf(type, ptr_depth, address, size, "FOO=BAR", strlen("FOO=BAR")+1);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool execve_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_buf((char*)ctx->arg[0], strlen((char*)ctx->arg[0])+1, "/tmp/hi", strlen("/tmp/hi")+1);
  else if (arg_num == 1) return einstein_rewrite_check_ppchar((char**)ctx->arg[1], "/tmp/hi", strlen("/tmp/hi")+1);
  else if (arg_num == 2) return einstein_rewrite_check_ppchar((char**)ctx->arg[2], "FOO=BAR", strlen("FOO=BAR")+1);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// int execveat(int dirfd, const char *pathname, char *const argv[], char *const envp[], int flags);
static bool execveat_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_tainted_dword(ctx->arg_taint[0]) ||
      is_tainted_vptr((char*)ctx->arg[1], ctx->arg_taint[1], strlen((char*)ctx->arg[1])+1) ||
      is_tainted_ppchar((char**)ctx->arg[2], ctx->arg_taint[2]) ||
      is_tainted_ppchar((char**)ctx->arg[3], ctx->arg_taint[3]) ||
      is_tainted_dword(ctx->arg_taint[4]);
}
static string execveat_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_dword(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_vptr((char*)ctx->arg[1], ctx->arg_taint[1], strlen((char*)ctx->arg[1])+1) + ", " +
      details_ppchar((char**)ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_ppchar((char**)ctx->arg[3], ctx->arg_taint[3]) + ", " +
      details_dword(ctx->arg[4], ctx->arg_taint[4]) + "]";
}
static void execveat_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 1) einstein_rewrite_init_buf(type, ptr_depth, address, size, "/tmp/hi", strlen("/tmp/hi")+1);
  else if (arg_num == 2) einstein_rewrite_init_buf(type, ptr_depth, address, size, "/tmp/hi", strlen("/tmp/hi")+1);
  else if (arg_num == 3) einstein_rewrite_init_buf(type, ptr_depth, address, size, "FOO=BAR", strlen("FOO=BAR")+1);
  else if (arg_num == 4) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool execveat_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_int(&ctx->arg[0], 34);
  else if (arg_num == 1) return einstein_rewrite_check_buf((char*)ctx->arg[1], strlen((char*)ctx->arg[1])+1, "/tmp/hi", strlen("/tmp/hi")+1);
  else if (arg_num == 2) return einstein_rewrite_check_ppchar((char**)ctx->arg[2], "/tmp/hi", strlen("/tmp/hi")+1);
  else if (arg_num == 3) return einstein_rewrite_check_ppchar((char**)ctx->arg[3], "FOO=BAR", strlen("FOO=BAR")+1);
  else if (arg_num == 4) return einstein_rewrite_check_int(&ctx->arg[4], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
static bool mmap_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_tainted_qword(ctx->arg_taint[0]) ||
      is_tainted_qword(ctx->arg_taint[1]) ||
      is_tainted_dword(ctx->arg_taint[2]) ||
      is_tainted_dword(ctx->arg_taint[3]) ||
      is_controllable_fd((int)ctx->arg[4], ctx->arg_taint[4]) ||
      is_tainted_dword(ctx->arg_taint[5]); /* Our off_t is apparently 32-bit */
}
static string mmap_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_qword(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_qword(ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_dword(ctx->arg[3], ctx->arg_taint[3]) + ", " +
      details_fd(ctx->arg[4], ctx->arg_taint[4]) + ", " +
      details_dword(ctx->arg[5], ctx->arg_taint[5]) + "]"; /* Our off_t is apparently 32-bit */
}
static void mmap_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_vptr(type, ptr_depth, address, size, (void*)0x7fff00123456);
  else if (arg_num == 1) einstein_rewrite_init_sizet(type, ptr_depth, address, size, 34);
  else if (arg_num == 2) einstein_rewrite_init_int(type, ptr_depth, address, size, PROT_EXEC|PROT_WRITE);
  else if (arg_num == 3) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 4) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 5) einstein_rewrite_init_offt(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool mmap_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_vptr(&ctx->arg[0], (void*)0x7fff00123456);
  else if (arg_num == 1) return einstein_rewrite_check_sizet(&ctx->arg[1], 34);
  else if (arg_num == 2) return einstein_rewrite_check_int(&ctx->arg[2], PROT_EXEC|PROT_WRITE);
  else if (arg_num == 3) return einstein_rewrite_check_int(&ctx->arg[3], 34);
  else if (arg_num == 4) return einstein_rewrite_check_int(&ctx->arg[4], 34);
  else if (arg_num == 5) return einstein_rewrite_check_offt(&ctx->arg[5], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// int mprotect(void *addr, size_t len, int prot);
static bool mprotect_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_tainted_qword(ctx->arg_taint[0]) ||
      is_tainted_qword(ctx->arg_taint[1]) ||
      is_tainted_dword(ctx->arg_taint[2]);
}
static string mprotect_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_qword(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_qword(ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + "]";
}
static void mprotect_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_vptr(type, ptr_depth, address, size, (void*)0x7fff00123456);
  else if (arg_num == 1) einstein_rewrite_init_sizet(type, ptr_depth, address, size, 34);
  else if (arg_num == 2) einstein_rewrite_init_int(type, ptr_depth, address, size, PROT_EXEC|PROT_WRITE);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool mprotect_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_vptr(&ctx->arg[0], (void*)0x7fff00123456);
  else if (arg_num == 1) return einstein_rewrite_check_sizet(&ctx->arg[1], 34);
  else if (arg_num == 2) return einstein_rewrite_check_int(&ctx->arg[2], PROT_EXEC|PROT_WRITE);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// void *mremap(void *old_address, size_t old_size, size_t new_size, int flags, ... /* void *new_address */);
static bool mremap_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_tainted_qword(ctx->arg_taint[0]) ||
      is_tainted_qword(ctx->arg_taint[1]) ||
      is_tainted_qword(ctx->arg_taint[2]) ||
      is_tainted_dword(ctx->arg_taint[3]) ||
      is_tainted_qword(ctx->arg_taint[4]);  // TODO: The new_address argument is optional. Only check it if flags contains MREMAP_FIXED.
}
static string mremap_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_qword(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_qword(ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_qword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_dword(ctx->arg[3], ctx->arg_taint[3]) + ", " +
      details_qword(ctx->arg[4], ctx->arg_taint[4]) + "]";
}
static void mremap_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_vptr(type, ptr_depth, address, size, (void*)0x7fff00123456);
  else if (arg_num == 1) einstein_rewrite_init_sizet(type, ptr_depth, address, size, 34);
  else if (arg_num == 2) einstein_rewrite_init_sizet(type, ptr_depth, address, size, 34);
  else if (arg_num == 3) einstein_rewrite_init_int(type, ptr_depth, address, size, 0x7);
  else if (arg_num == 4) einstein_rewrite_init_vptr(type, ptr_depth, address, size, (void*)0x7fff00123456);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool mremap_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_vptr(&ctx->arg[0], (void*)0x7fff00123456);
  else if (arg_num == 1) return einstein_rewrite_check_sizet(&ctx->arg[1], 34);
  else if (arg_num == 2) return einstein_rewrite_check_sizet(&ctx->arg[2], 34);
  else if (arg_num == 3) return einstein_rewrite_check_int(&ctx->arg[3], 0x7);
  else if (arg_num == 4) return einstein_rewrite_check_vptr(&ctx->arg[4], (void*)0x7fff00123456);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// int remap_file_pages(void *addr, size_t size, int prot, size_t pgoff, int flags);
static bool remap_file_pages_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_tainted_qword(ctx->arg_taint[0]) ||
      is_tainted_qword(ctx->arg_taint[1]) ||
      is_tainted_dword(ctx->arg_taint[2]) ||
      is_tainted_qword(ctx->arg_taint[3]) ||
      is_tainted_dword(ctx->arg_taint[4]);
}
static string remap_file_pages_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_qword(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_qword(ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_qword(ctx->arg[3], ctx->arg_taint[3]) + ", " +
      details_dword(ctx->arg[4], ctx->arg_taint[4]) + "]";
}
static void remap_file_pages_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_vptr(type, ptr_depth, address, size, (void*)0x7fff00123456);
  else if (arg_num == 1) einstein_rewrite_init_sizet(type, ptr_depth, address, size, 34);
  else if (arg_num == 2) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 3) einstein_rewrite_init_sizet(type, ptr_depth, address, size, 34);
  else if (arg_num == 4) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool remap_file_pages_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_vptr(&ctx->arg[0], (void*)0x7fff00123456);
  else if (arg_num == 1) return einstein_rewrite_check_sizet(&ctx->arg[1], 34);
  else if (arg_num == 2) return einstein_rewrite_check_int(&ctx->arg[2], 34);
  else if (arg_num == 3) return einstein_rewrite_check_sizet(&ctx->arg[3], 34);
  else if (arg_num == 4) return einstein_rewrite_check_int(&ctx->arg[3], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// ssize_t sendfile(int out_fd, int in_fd, off_t *offset, size_t count);
static bool sendfile_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_controllable_fd((int)ctx->arg[0], ctx->arg_taint[0]) ||
      is_controllable_fd((int)ctx->arg[1], ctx->arg_taint[1]) ||
      is_tainted_vptr((void*)ctx->arg[2], ctx->arg_taint[2], sizeof(off_t)) ||
      is_tainted_qword(ctx->arg_taint[3]);
}
static string sendfile_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_fd(ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_vptr((void*)ctx->arg[2], ctx->arg_taint[2], sizeof(off_t)) + ", " +
      details_qword(ctx->arg[3], ctx->arg_taint[3]) + "]";
}
static void sendfile_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 1) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 2) einstein_rewrite_init_offt(type, ptr_depth, address, size, 34);
  else if (arg_num == 3) einstein_rewrite_init_sizet(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool sendfile_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_int(&ctx->arg[0], 34);
  else if (arg_num == 1) return einstein_rewrite_check_int(&ctx->arg[1], 34);
  else if (arg_num == 2) return einstein_rewrite_check_offt(&ctx->arg[2], 34);
  else if (arg_num == 3) return einstein_rewrite_check_sizet(&ctx->arg[3], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// int sendmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, int flags);
static bool sendmmsg_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_controllable_sockfd((int)ctx->arg[0], ctx->arg_taint[0]) ||
      is_tainted_vptr((void*)ctx->arg[1], ctx->arg_taint[1], sizeof(struct mmsghdr)) ||
      is_tainted_dword(ctx->arg_taint[2]) ||
      is_tainted_dword(ctx->arg_taint[3]);
}
static string sendmmsg_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_vptr((void*)ctx->arg[1], ctx->arg_taint[1], sizeof(struct mmsghdr)) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_dword(ctx->arg[3], ctx->arg_taint[3]) + "]";
}
static void sendmmsg_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  //else if (arg_num == 1) // TODO: Handle struct mmsghdr*
  else if (arg_num == 2) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 3) einstein_rewrite_init_int(type, ptr_depth, address, size, MSG_CONFIRM|MSG_EOR|MSG_MORE);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool sendmmsg_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_int(&ctx->arg[0], 34);
  //else if (arg_num == 1) // TODO: Handle struct mmsghdr*
  else if (arg_num == 2) return einstein_rewrite_check_int(&ctx->arg[2], 34);
  else if (arg_num == 3) return einstein_rewrite_check_int(&ctx->arg[3], MSG_CONFIRM|MSG_EOR|MSG_MORE);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// ssize_t sendmsg(int sockfd, const struct msghdr *msg, int flags);
static bool sendmsg_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_controllable_sockfd((int)ctx->arg[0], ctx->arg_taint[0]) ||
      is_tainted_vptr((void*)ctx->arg[1], ctx->arg_taint[1], sizeof(struct msghdr)) ||
      is_tainted_dword(ctx->arg_taint[2]);
}
static string sendmsg_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_vptr((void*)ctx->arg[1], ctx->arg_taint[1], sizeof(struct msghdr)) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + "]";
}
static void sendmsg_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  //else if (arg_num == 1) // TODO: Handle struct msghdr*
  else if (arg_num == 2) einstein_rewrite_init_int(type, ptr_depth, address, size, MSG_CONFIRM|MSG_EOR|MSG_MORE);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool sendmsg_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_int(&ctx->arg[0], 34);
  //else if (arg_num == 1) // TODO: Handle struct msghdr*
  else if (arg_num == 2) return einstein_rewrite_check_int(&ctx->arg[2], MSG_CONFIRM|MSG_EOR|MSG_MORE);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen);
static bool sendto_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_controllable_sockfd((int)ctx->arg[0], ctx->arg_taint[0]) ||
      is_tainted_vptr((void*)ctx->arg[1], ctx->arg_taint[1], (size_t)ctx->arg[2]) ||
      is_tainted_qword(ctx->arg_taint[2]) ||
      is_tainted_dword(ctx->arg_taint[3]) ||
      is_tainted_sockaddr((const struct sockaddr *)ctx->arg[4], ctx->arg_taint[4], (socklen_t)ctx->arg[5]) ||
      is_tainted_qword(ctx->arg_taint[5]);
}
static string sendto_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_vptr((void*)ctx->arg[1], ctx->arg_taint[1], (size_t)ctx->arg[2]) + ", " +
      details_qword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_dword(ctx->arg[3], ctx->arg_taint[3]) + ", " +
      details_sockaddr((const struct sockaddr *)ctx->arg[4], ctx->arg_taint[4], (socklen_t)ctx->arg[5]) + ", " +
      details_dword(ctx->arg[5], ctx->arg_taint[5]) + "]";
}
static void sendto_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 1) einstein_rewrite_init_buf(type, ptr_depth, address, size, "HELLO", strlen("HELLO"));
  else if (arg_num == 2) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 3) einstein_rewrite_init_int(type, ptr_depth, address, size, MSG_CONFIRM|MSG_EOR|MSG_MORE);
  //else if (arg_num == 4) // TODO: Handle struct sockaddr*
  else if (arg_num == 5) einstein_rewrite_init_socklent(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool sendto_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_int(&ctx->arg[0], 34);
  else if (arg_num == 1) return einstein_rewrite_check_buf((char*)ctx->arg[1], (size_t)ctx->arg[2], "HELLO", strlen("HELLO"));
  else if (arg_num == 2) return einstein_rewrite_check_int(&ctx->arg[2], 34);
  else if (arg_num == 3) return einstein_rewrite_check_int(&ctx->arg[3], MSG_CONFIRM|MSG_EOR|MSG_MORE);
  //else if (arg_num == 4) // TODO: Handle struct sockaddr*
  else if (arg_num == 5) return einstein_rewrite_check_socklent(&ctx->arg[5], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// ssize_t write(int fd, const void *buf, size_t count);
static bool write_arg_is_tainted(syscall_ctx_t *ctx) {
  return is_controllable_fd((int)ctx->arg[0], ctx->arg_taint[0]) || is_tainted_vptr((char*)ctx->arg[1], ctx->arg_taint[1], (size_t)ctx->arg[2]);
}
static string write_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_vptr((char*)ctx->arg[1], ctx->arg_taint[1], (size_t)ctx->arg[2]) + ", " +
      details_qword(ctx->arg[2], ctx->arg_taint[2]) + "]";
}
static void write_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 1) einstein_rewrite_init_buf(type, ptr_depth, address, size, "HELLO", strlen("HELLO"));
  else if (arg_num == 2) einstein_rewrite_init_sizet(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool write_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_int(&ctx->arg[0], 34);
  else if (arg_num == 1) return einstein_rewrite_check_buf((char*)ctx->arg[1], (size_t)ctx->arg[2], "HELLO", strlen("HELLO"));
  else if (arg_num == 2) return einstein_rewrite_check_sizet(&ctx->arg[2], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// ssize_t pwrite64(int fd, const void *buf, size_t count, off_t offset);
static bool pwrite64_arg_is_tainted(syscall_ctx_t *ctx) { return write_arg_is_tainted(ctx); }
static string pwrite64_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_vptr((char*)ctx->arg[1], ctx->arg_taint[1], (size_t)ctx->arg[2]) + ", " +
      details_qword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_dword(ctx->arg[3], ctx->arg_taint[3]) + "]"; /* Our off_t is apparently 32-bit */
}
static void pwrite64_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0 || arg_num == 1 || arg_num == 2) write_rewrite_init(type, ptr_depth, arg_num, address, size);
  else if (arg_num == 3) einstein_rewrite_init_offt(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool pwrite64_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0 || arg_num == 1 || arg_num == 2) return write_rewrite_check(ctx, arg_num);
  else if (arg_num == 3) return einstein_rewrite_check_offt(&ctx->arg[3], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// ssize_t writev(int fd, const struct iovec *iov, int iovcnt);
static bool writev_arg_is_tainted(syscall_ctx_t *ctx) {
  return is_controllable_fd((int)ctx->arg[0], ctx->arg_taint[0]) || is_tainted_iovec((const struct iovec*)ctx->arg[1], ctx->arg_taint[1], (int)ctx->arg[2]);
}
static string writev_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_iovec((const struct iovec*)ctx->arg[1], ctx->arg_taint[1], (int)ctx->arg[2]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + "]";
}
static void writev_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else if (arg_num == 1) einstein_rewrite_init_buf(type, ptr_depth, address, size, "HELLO", strlen("HELLO"));
  else if (arg_num == 2) einstein_rewrite_init_int(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool writev_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0) return einstein_rewrite_check_int(&ctx->arg[0], 34);
  else if (arg_num == 1) return einstein_rewrite_check_iovec((struct iovec *)ctx->arg[1], (size_t)ctx->arg[2], "HELLO", strlen("HELLO"));
  else if (arg_num == 2) return einstein_rewrite_check_sizet(&ctx->arg[2], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// ssize_t pwritev(int fd, const struct iovec *iov, int iovcnt, off_t offset);
static bool pwritev_arg_is_tainted(syscall_ctx_t *ctx) { return writev_arg_is_tainted(ctx); }
static string pwritev_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_iovec((const struct iovec*)ctx->arg[1], ctx->arg_taint[1], (int)ctx->arg[2]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_dword(ctx->arg[3], ctx->arg_taint[3]) + "]"; /* Our off_t is apparently 32-bit */
}
static void pwritev_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0 || arg_num == 1 || arg_num == 2) writev_rewrite_init(type, ptr_depth, arg_num, address, size);
  else if (arg_num == 3) einstein_rewrite_init_offt(type, ptr_depth, address, size, 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool pwritev_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0 || arg_num == 1 || arg_num == 2) return writev_rewrite_check(ctx, arg_num);
  else if (arg_num == 3) return einstein_rewrite_check_offt(&ctx->arg[3], 34);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// ssize_t pwritev2(int fd, const struct iovec *iov, int iovcnt, off_t offset, int flags);
static bool pwritev2_arg_is_tainted(syscall_ctx_t *ctx) { return writev_arg_is_tainted(ctx); }
static string pwritev2_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_iovec((const struct iovec*)ctx->arg[1], ctx->arg_taint[1], (int)ctx->arg[2]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_dword(ctx->arg[3], ctx->arg_taint[3]) + ", " +/* Our off_t is apparently 32-bit */
      details_dword(ctx->arg[4], ctx->arg_taint[4]) + "]";
}
static void pwritev2_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 0 || arg_num == 1 || arg_num == 2) writev_rewrite_init(type, ptr_depth, arg_num, address, size);
  else if (arg_num == 3) einstein_rewrite_init_offt(type, ptr_depth, address, size, 34);
  else if (arg_num == 4) einstein_rewrite_init_int(type, ptr_depth, address, size, 0xf);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool pwritev2_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 0 || arg_num == 1 || arg_num == 2) return writev_rewrite_check(ctx, arg_num);
  else if (arg_num == 3) return einstein_rewrite_check_offt(&ctx->arg[3], 34);
  else if (arg_num == 4) return einstein_rewrite_check_int(&ctx->arg[4], 0xf);
  else EINSTEIN_EXIT_UNREACHABLE();
}

// ==========================================================================================================================================
// ==========================================================================================================================================
// Handlers: FD creator syscalls

// =====================================================================
// int open(const char *pathname, int flags, mode_t mode);
static bool open_arg_is_tainted(syscall_ctx_t *ctx) {
  return is_tainted_vptr((char*)ctx->arg[0], ctx->arg_taint[0], strlen((char*)ctx->arg[0])+1) &&
         (is_tainted_dword(ctx->arg_taint[1]) ||
          flags_is_writable(ctx->arg[1]));
}
static string open_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_vptr((char*)ctx->arg[0], ctx->arg_taint[0], strlen((char*)ctx->arg[0])+1) + ", " +
      details_none() + ", " +
      details_none() + "]";
}

// =====================================================================
// int openat(int dirfd, const char *pathname, int flags, mode_t mode);
static bool openat_arg_is_tainted(syscall_ctx_t *ctx) {
  return is_tainted_vptr((char*)ctx->arg[1], ctx->arg_taint[1], strlen((char*)ctx->arg[1])+1) &&
         (is_tainted_dword(ctx->arg_taint[2]) ||
          flags_is_writable(ctx->arg[2]));
}
static string openat_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_none() + ", " +
      details_vptr((char*)ctx->arg[1], ctx->arg_taint[1], strlen((char*)ctx->arg[1])+1) + ", " +
      details_none() + ", " +
      details_none() + "]";
}
static void openat_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  if (arg_num == 1) einstein_rewrite_init_buf(type, ptr_depth, address, size, "/tmp/hi", strlen("/tmp/hi")+1);
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool openat_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  if (arg_num == 1) return einstein_rewrite_check_buf((char*)ctx->arg[1], strlen((char*)ctx->arg[1])+1, "/tmp/hi", strlen("/tmp/hi")); // Not including NULL-terminator in length because it may be concatenated
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// long openat2(int dirfd, const char *pathname, struct open_how *how, size_t size);
static bool openat2_arg_is_tainted(syscall_ctx_t *ctx) {
  // TODO: Check if how->flags is writable
  return is_tainted_vptr((char*)ctx->arg[1], ctx->arg_taint[1], strlen((char*)ctx->arg[1])+1);
}
static string openat2_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_none() + ", " +
      details_vptr((char*)ctx->arg[1], ctx->arg_taint[1], strlen((char*)ctx->arg[1])+1) + ", " +
      details_none() + ", " +
      details_none() + "]";
}

// =====================================================================
// int creat(const char *pathname, mode_t mode);
static bool creat_arg_is_tainted(syscall_ctx_t *ctx) {
  return is_tainted_vptr((char*)ctx->arg[0], ctx->arg_taint[0], strlen((char*)ctx->arg[0])+1);
}
static string creat_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_vptr((char*)ctx->arg[0], ctx->arg_taint[0], strlen((char*)ctx->arg[0])+1) + ", " +
      details_none()+ "]";
}

// =====================================================================
// =====================================================================
// int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
static bool bind_arg_is_tainted(syscall_ctx_t *ctx) {
  return is_tainted_sockaddr((const struct sockaddr *)ctx->arg[1], ctx->arg_taint[1], (socklen_t)ctx->arg[2]);
}
static string bind_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_none() + ", " +
      details_sockaddr((const struct sockaddr *)ctx->arg[1], ctx->arg_taint[1], (socklen_t)ctx->arg[2]) + ", " +
      details_none() + "]";
}
static void bind_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) {
  struct sockaddr_in canary_sockaddr = SOCKADDR_CANARY();
  if (arg_num == 1) einstein_rewrite_init_buf(type, ptr_depth, address, size, &canary_sockaddr, sizeof(struct sockaddr_in));
  else EINSTEIN_EXIT_UNREACHABLE();
}
static bool bind_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) {
  struct sockaddr_in canary_sockaddr = SOCKADDR_CANARY();
  if (arg_num == 1) return einstein_rewrite_check_buf((char*)ctx->arg[1], (socklen_t)ctx->arg[2], &canary_sockaddr, sizeof(struct sockaddr_in));
  else EINSTEIN_EXIT_UNREACHABLE();
}

// =====================================================================
// int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
static bool connect_arg_is_tainted(syscall_ctx_t *ctx) { return bind_arg_is_tainted(ctx); }
static string connect_get_details(syscall_ctx_t *ctx) { return bind_get_details(ctx); }
static void connect_rewrite_init(string type, size_t ptr_depth, size_t arg_num, uint8_t * address, size_t size) { bind_rewrite_init(type, ptr_depth, arg_num, address, size); }
static bool connect_rewrite_check(syscall_ctx_t *ctx, size_t arg_num) { return bind_rewrite_check(ctx, arg_num); }

// =====================================================================
// int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
static bool setsockopt_arg_is_tainted(syscall_ctx_t *ctx) {
  if (is_controllable_fd((int)ctx->arg[0], ctx->arg_taint[0])) return false; // This FD is already controllable, no need to report
  return
      is_tainted_dword(ctx->arg_taint[1]) ||
      is_tainted_dword(ctx->arg_taint[2]) ||
      is_tainted_vptr((void*)ctx->arg[3], ctx->arg_taint[3], (socklen_t)ctx->arg[4]);
}
static string setsockopt_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_dword(ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_vptr((void*)ctx->arg[3], ctx->arg_taint[3], (socklen_t)ctx->arg[4]) + ", " +
      details_none() + "]";
}

// =====================================================================
// int socket(int domain, int type, int protocol);
static bool socket_arg_is_tainted(syscall_ctx_t *ctx) {
  return
      is_tainted_dword(ctx->arg_taint[0]) ||
      is_tainted_dword(ctx->arg_taint[1]) ||
      is_tainted_dword(ctx->arg_taint[2]);
}
static string socket_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_dword(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_dword(ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + "]";
}

// =====================================================================
// int socketpair(int domain, int type, int protocol, int sv[2]);
static bool socketpair_arg_is_tainted(syscall_ctx_t *ctx) { return socket_arg_is_tainted(ctx); }
static string socketpair_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_dword(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_dword(ctx->arg[1], ctx->arg_taint[1]) + ", " +
      details_dword(ctx->arg[2], ctx->arg_taint[2]) + ", " +
      details_none() + "]";
}

// =====================================================================
// =====================================================================
// int dup(int oldfd);
static bool dup_arg_is_tainted(syscall_ctx_t *ctx) {
  return is_controllable_fd((int)ctx->arg[0], ctx->arg_taint[0]);
}
static string dup_get_details(syscall_ctx_t *ctx) {
  return "[" + details_fd(ctx->arg[0], ctx->arg_taint[0])+ "]";
}

// =====================================================================
// int dup2(int oldfd, int newfd);
static bool dup2_arg_is_tainted(syscall_ctx_t *ctx) { return dup_arg_is_tainted(ctx); }
static string dup2_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_none() + "]";
}

// =====================================================================
// int dup3(int oldfd, int newfd, int flags);
static bool dup3_arg_is_tainted(syscall_ctx_t *ctx) { return dup_arg_is_tainted(ctx); }
static string dup3_get_details(syscall_ctx_t *ctx) {
  return "[" +
      details_fd(ctx->arg[0], ctx->arg_taint[0]) + ", " +
      details_none() + ", " +
      details_none() + "]";
}

// ==========================================================================================================================================
// ==========================================================================================================================================
// Other interfaces

// =====================================================================
void fd_create(int fd, unsigned long long this_report_num, syscall_ctx_t *ctx) { fd_create_internal(fd, this_report_num, ctx); }
void fd_close(int fd) { fd_close_internal(fd); }

// =====================================================================
std::set<int> syscalls_fd_creators;
std::set<int> syscalls_sec_sensitive;
std::set<int> syscalls_sec_sensitive_write;

bool is_syscall_fd_creator(int nr) {
  return syscalls_fd_creators.find(nr) != syscalls_fd_creators.end();
}
bool is_syscall_sec_sensitive(int nr) {
  if (syscalls_sec_sensitive.find(nr) != syscalls_sec_sensitive.end()) return true;
  if (syscalls_sec_sensitive_write.find(nr) != syscalls_sec_sensitive_write.end()) return hook_writes;
  return false;
}

einstein_syscall_t einstein_syscalls[SYSCALL_MAX];

#define IMPL_SYS(n) do { einstein_syscalls[__NR_ ## n].name = #n; \
                         einstein_syscalls[__NR_ ## n].arg_is_tainted = n ## _arg_is_tainted; \
                         einstein_syscalls[__NR_ ## n].get_details = n ## _get_details; \
                        } while (0)
#define IMPL_FDCREAT(n) do { IMPL_SYS(n); syscalls_fd_creators.insert(__NR_ ## n); } while (0)
#define IMPL_SECSENS(n) do { IMPL_SYS(n); syscalls_sec_sensitive.insert(__NR_ ## n); } while (0)
#define IMPL_SECSENSW(n) do { IMPL_SYS(n); syscalls_sec_sensitive_write.insert(__NR_ ## n); } while (0)

#define REWRITE(n)  do { einstein_syscalls[__NR_ ## n].rewrite_init = n ## _rewrite_init; \
                        einstein_syscalls[__NR_ ## n].rewrite_check = n ## _rewrite_check; \
                       } while (0)

static void einstein_syscalls_init_impl(void) {
  // Identification handlers: FD-configuring syscalls
  IMPL_FDCREAT(bind);
  IMPL_FDCREAT(connect);
  IMPL_FDCREAT(creat);
  IMPL_FDCREAT(dup);
  IMPL_FDCREAT(dup2);
  IMPL_FDCREAT(dup3);
  IMPL_FDCREAT(open);
  IMPL_FDCREAT(openat);
  IMPL_FDCREAT(openat2);
  IMPL_FDCREAT(setsockopt);
  IMPL_FDCREAT(socket);
  IMPL_FDCREAT(socketpair);
  // TODO: Add other fd creators? I.e.: accept, accept4, pipe, pipe2, epoll_create, signalfd, eventfd, timerfd_create, memfd_create, userfaultfd, fanotify_init, inotify_init, clone (with CLONE_PIDFD), pidfd_open, open_by_handle_at, ...
  // NOTE: If any fdcreators are added, make sure they are handled by einstein_post_fd_creator_hook()

  // Identification handlers: Sec-sensitive syscalls
  IMPL_SECSENS(execve);
  IMPL_SECSENS(execveat);
  IMPL_SECSENS(mmap);
  IMPL_SECSENS(mprotect);
  IMPL_SECSENS(mremap);
  IMPL_SECSENS(remap_file_pages);
  IMPL_SECSENS(sendfile);
  IMPL_SECSENS(sendmmsg);
  IMPL_SECSENS(sendmsg);
  IMPL_SECSENS(sendto);

  // Identification handlers: Sec-sensitive syscalls, writes only
  IMPL_SECSENSW(pwrite64);
  IMPL_SECSENSW(pwritev);
  IMPL_SECSENSW(pwritev2);
  IMPL_SECSENSW(write);
  IMPL_SECSENSW(writev);

  // Rewrite handlers: Sec-sensitive syscalls
  REWRITE(execve);
  REWRITE(execveat);
  REWRITE(mmap);
  REWRITE(mprotect);
  REWRITE(mremap);
  REWRITE(pwrite64);
  REWRITE(pwritev);
  REWRITE(pwritev2);
  REWRITE(remap_file_pages);
  REWRITE(sendfile);
  REWRITE(sendmmsg);
  REWRITE(sendmsg);
  REWRITE(sendto);
  REWRITE(write);
  REWRITE(writev);

  // Rewrite handlers: FD-configuring syscalls
  REWRITE(bind);
  REWRITE(connect);
  //REWRITE(creat);
  //REWRITE(dup);
  //REWRITE(dup2);
  //REWRITE(dup3);
  //REWRITE(open);
  REWRITE(openat);
  //REWRITE(openat2);
  //REWRITE(setsockopt);
  //REWRITE(socket);
  //REWRITE(socketpair);
}
void einstein_syscalls_init(void) {
  einstein_syscalls_init_unimpl();
  einstein_syscalls_init_impl();
}