#include "einstein_common.h"
#include "einstein_utils.h"
#include "einstein_syscalls.h"

// =====================================================================
// FD tracking
// =====================================================================

typedef struct {
  unsigned long long report_num; // report_num == 0 ==> untainted
  string name;
  string type;
  int flags;
  tagqarr_t flags_taint;
} fd_info;
static std::unordered_map<int, fd_info> fds_all;

// =====================================================================
// Adding and looking up into fds_all

void all_fds_add(int fd, unsigned long long report_num, string type, string name, int flags, tagqarr_t flags_taint) { fds_all[fd] = {.report_num = report_num, .name = name, .type = type, .flags = flags, .flags_taint = flags_taint}; }
static bool fd_is_open(int fd) { return fds_all.find(fd) != fds_all.end(); }
static bool fd_is_tainted(int fd) { return fd_is_open(fd) && fds_all[fd].report_num != 0; } // This fd is open and is tainted

static void all_fds_add_if_unknown(int fd) {
  if (fd_is_open(fd)) return; // No need to call fstat if we're already tracking this FD
  struct stat sb;
  string t = "FD-TYPE-UNKNOWN";
  if (fstat(fd, &sb) == -1) {
    EINSTEIN_LOG("Error calling fstat from all_fds_add_if_unknown() for fd = %d\n", fd);
    t = "all_fds_add_if_unknown:ERROR-FD";
  } else {
    switch (sb.st_mode & S_IFMT) {
      case S_IFBLK:  /* block device */
      case S_IFCHR:  /* character device */
      case S_IFDIR:  /* directory */
      case S_IFLNK:  /* symlink */
      case S_IFREG:  /* regular file */
        t = "FILE-FD";
        break;
      case S_IFSOCK: /* socket */
        t = "SOCKET-FD";
        break;
      case S_IFIFO:  /* FIFO/pipe */
      default:       /* unknown? */
        break;
    }
  }
  all_fds_add(fd, 0, t, "", 0, tagqarr_t());
}

//static bool is_file_fd(int fd) { all_fds_add_if_unknown(fd); return fds_all[fd].type == "FILE-FD"; }
static bool is_socket_fd(int fd) { all_fds_add_if_unknown(fd); return fds_all[fd].type == "SOCKET-FD"; }

static bool is_an_open_tainted_fd(void) {
  for (auto it = fds_all.begin(); it != fds_all.end(); it++) {
    if (fd_is_tainted(it->first)) return true;
  }
  return false;
}
static bool is_an_open_tainted_sockfd(void) {
  for (auto it = fds_all.begin(); it != fds_all.end(); it++) {
    if (fd_is_tainted(it->first) && is_socket_fd(it->first)) return true;
  }
  return false;
}

// =====================================================================
// fd_info field helpers

static string fdcreator_get_name(syscall_ctx_t *ctx) {
  if (ctx->nr == __NR_open || ctx->nr == __NR_creat) return string((char*)ctx->arg[0]);
  else if (ctx->nr == __NR_openat || ctx->nr == __NR_openat2) return string((char*)ctx->arg[1]);
  return "";
}

static int fdcreator_get_flags(syscall_ctx_t *ctx) {
  if (ctx->nr == __NR_open) return (int)ctx->arg[1] & 0xffffffff;
  if (ctx->nr == __NR_openat) return (int)ctx->arg[2] & 0xffffffff;
  if (ctx->nr == __NR_creat) return (O_CREAT|O_WRONLY|O_TRUNC) & 0xffffffff;
  if (ctx->nr == __NR_openat2) return 0; // TODO
  return 0;
}

static tagqarr_t fdcreator_get_flagstaint(syscall_ctx_t *ctx) {
  if (ctx->nr == __NR_open) return ctx->arg_taint[1];
  if (ctx->nr == __NR_openat) return ctx->arg_taint[2];
  if (ctx->nr == __NR_creat) return tagqarr_t();
  if (ctx->nr == __NR_openat2) return tagqarr_t(); // TODO
  return tagqarr_t();
}

static string syscall_nr_to_fd_type(int syscall_num) {
  switch (syscall_num) {
    case __NR_dup:
    case __NR_dup2:
    case __NR_dup3:
      return "DUP-FD";
    case __NR_creat:
    case __NR_open:
    case __NR_openat:
    case __NR_openat2:
      return "FILE-FD";
    case __NR_bind:
    case __NR_connect:
    case __NR_setsockopt:
    case __NR_socket:
    case __NR_socketpair:
      return "SOCKET-FD";
    default:
      return "FD-TYPE-UNKNOWN";
  }
}

// =====================================================================
// High-level interface for checking FDs

static string fd_get_info_str(int fd) {
  all_fds_add_if_unknown(fd);
  fd_info fdi = fds_all[fd];
  return "{\"fd\": " + std::to_string(fd) + ", " +
          "\"report_num\": " + std::to_string(fdi.report_num) + ", " +
          "\"type\": \"" + fdi.type + "\", " +
          "\"name\": \"" + fdi.name + "\", " +
          "\"flags\": \"" + flags_to_str(fdi.flags) + "\", \"flags_taint\": " + tagdarr_sprint(fdi.flags_taint) +
          "}";
}

static string fd_get_single_tainted_strarr(int fd) {
  if (!fd_is_tainted(fd)) return "[]";
  return "[" + fd_get_info_str(fd) + "]";
}

static string fd_get_all_tainted_strarr(void) {
  // Get the first tainted FD (to properly format the list string)
  auto it = fds_all.begin();
  for (; it != fds_all.end(); it++) {
    if (fd_is_tainted(it->first)) break;
  }
  if (it == fds_all.end()) return "[]"; // No open tainted fds
  string s = "[" + fd_get_info_str(it->first);

  // Get the rest of the tainted FDs
  for (it++; it != fds_all.end(); it++) {
    if (fd_is_tainted(it->first)) s += ", " + fd_get_info_str(it->first);
  }
  s += "]";
  return s;
}

void fd_create_internal(int fd, unsigned long long this_report_num, syscall_ctx_t *ctx) {
  string name = fdcreator_get_name(ctx);
  int flags = fdcreator_get_flags(ctx);
  tagqarr_t flags_taint = fdcreator_get_flagstaint(ctx);
  string type = syscall_nr_to_fd_type(ctx->nr);

  //EINSTEIN_LOG("fd_create(fd = %x, this_report_num = %llx, name = '%s');\n", fd, this_report_num, name.c_str());
  // Commenting the below check out because a fd may have multiple "creations" (more like "configurations"), e.g., socket->connect->write
  // TODO: Turn .report_num field of fd_info into a list, so that we can see the chain of multiple configurations
  //if (fd_is_open(fd)) EINSTEIN_EXIT("Error: Trying to add fd %d to fds_all multiple times!\n", fd);

  all_fds_add(fd, this_report_num, type, name, flags, flags_taint);
}

void fd_close_internal(int fd) {
  //EINSTEIN_LOG("fd_close(fd = %x);\n", fd);
  fds_all.erase(fd);
}

// =====================================================================
// Report details
// =====================================================================

static string details_dword_prefix(ADDRINT val, tagqarr_t val_taint) {
  return "{\"type\": \"DWORD\", \"dword\": " + ptr_to_string((void*)(val & 0xffffffff), false) + ", \"dword_taint\": " + tagdarr_sprint(val_taint);
}
string details_fd(ADDRINT fd, tagqarr_t fd_taint) {
  // If fd is untainted, then fd_creators is _this_ fd's creator; else, it's _all_ tainted fds' creators
  string fd_creators = tagdarr_is_empty(fd_taint) ? fd_get_single_tainted_strarr((int)fd) : fd_get_all_tainted_strarr();
  return details_dword_prefix(fd, fd_taint) + ", \"fd_creators\": " + fd_creators + ", \"this_fd_arg\": " + fd_get_info_str(fd) + "}";
}
string details_dword(ADDRINT val, tagqarr_t val_taint) {
  return details_dword_prefix(val, val_taint) + "}";
}

string details_qword(ADDRINT val, tagqarr_t val_taint) {
  return "{\"type\": \"QWORD\", \"qword\": " + ptr_to_string((void*)val, false) + ", \"qword_taint\": " + tagqarr_sprint(val_taint) + "}";
}

string details_vptr(void * ptr, tagqarr_t ptr_taint, size_t len) {
  // Pointer, pointer's taint
  string s = "{\"type\": \"VPTR\", \"qword\": " + ptr_to_string(ptr, false) + ", \"qword_taint\": " + tagqarr_sprint(ptr_taint) + ", ";
  if (ptr == NULL) return s + "\"str\": \"\", \"buf\": [], \"buf_taint\": []}";
  size_t new_len = std::min<size_t>(len, MAX_PCHAR_LEN);

  // Buf as a string
  char buf[new_len+1] = {0}; // +1 for the null-terminator
  for (size_t i = 0; i < new_len; i++) {
    char c = ((char*)ptr)[i];
    if (c == '\0' || !isprint(c)) c = '.'; // Just to be safe
    buf[i] = c;
  }
  s += "\"str\": \"" + str_to_json_str(string(buf).substr(0,new_len)) + "\", ";

  // Buf
  s += "\"buf\": [";
  if (new_len > 0) {
    const char * cptr = (char *) ptr;
    s += byte_to_string(cptr[0], false);
    for (size_t i = 1; i < new_len; i++)
      s += ", " + byte_to_string(cptr[i], false);
  }
  s += "], \"buf_taint\": ";

  // Buf's taint
  s += tagn_sprint((ADDRINT)ptr, new_len) + "}";

  return s;
}

string details_ppchar(char ** pptr, tagqarr_t pptr_taint) {
  string s = "{\"type\": \"PPCHAR\", \"qword\": " + ptr_to_string(pptr, false) + ", \"qword_taint\": " + tagqarr_sprint(pptr_taint) + ", ";

  if (pptr == NULL) return s + "\"pchars\": []}";

  s += "\"pchars\": [" + details_vptr(pptr[0], tagmap_getqarr((ADDRINT)&pptr[0]), pptr[0]==NULL ? 0 : strlen(pptr[0])+1);
  for (size_t i = 1; pptr[i - 1] != NULL && i < MAX_PPCHAR_LEN; i++)
    s += ", " + details_vptr(pptr[i], tagmap_getqarr((ADDRINT)&pptr[i]), pptr[i]==NULL ? 0 : strlen(pptr[i])+1);
  s += "]}";
  return s;
}

string details_iovec(const struct iovec *iov, tagqarr_t iov_taint, int iovcnt) {
  string s = "{\"type\": \"IOVEC\", \"qword\": " + ptr_to_string(iov, false) + ", \"qword_taint\": " + tagqarr_sprint(iov_taint) + ", ";
  if (iov == NULL) return s + "\"vptrs\": []}";

  s += "\"vptrs\": [" + details_vptr(iov[0].iov_base, tagmap_getqarr((ADDRINT)&iov[0].iov_base), iov[0].iov_len);
  for (int i = 1; i < std::min<int>(iovcnt, MAX_IOVEC_LEN); i++)
    s += ", " + details_vptr(iov[i].iov_base, tagmap_getqarr((ADDRINT)&iov[i].iov_base), iov[i].iov_len);
  s += "]}";

  return s;
}

string details_sockaddr(const struct sockaddr * addr, tagqarr_t addr_taint, socklen_t addrlen) {
  return details_vptr((void*)addr, addr_taint, addrlen); // TODO: Specially print sockaddr details. For now, let's just handle it as a vptr.
}

// =====================================================================
// Check if syscall is tainted
// =====================================================================

bool is_tainted_dword(tagqarr_t val_taint) {
  return !tagdarr_is_empty(val_taint);
}

bool is_tainted_qword(tagqarr_t val_taint) {
  return !tagqarr_is_empty(val_taint);
}

bool is_tainted_vptr(void * ptr, tagqarr_t ptr_taint, size_t len) {
  return is_tainted_qword(ptr_taint) ||
      (ptr != NULL && !tag_is_empty(tagmap_getn((ADDRINT)ptr, std::min<size_t>(len, MAX_PCHAR_LEN))));
}

bool is_tainted_ppchar(char ** pptr, tagqarr_t pptr_taint) {
  if (is_tainted_qword(pptr_taint)) return true;
  if (pptr != NULL) {
    if (is_tainted_vptr(pptr[0], tagmap_getqarr((ADDRINT)&pptr[0]), pptr[0]==NULL ? 0 : strlen(pptr[0])+1)) return true;
    for (size_t i = 1; pptr[i - 1] != NULL && i < MAX_PPCHAR_LEN; i++)
      if (is_tainted_vptr(pptr[i], tagmap_getqarr((ADDRINT)&pptr[i]), pptr[i]==NULL ? 0 : strlen(pptr[i])+1)) return true;
  }
  return false;
}

bool is_tainted_iovec(const struct iovec *iov, tagqarr_t iov_taint, int iovcnt) {
  if (is_tainted_qword(iov_taint)) return true;
  for (int i = 0; i < std::min<int>(iovcnt, MAX_IOVEC_LEN); i++) {
    if (is_tainted_vptr(iov[i].iov_base, tagmap_getqarr((ADDRINT)&iov[i].iov_base), iov[i].iov_len)) return true;
    // Not checking the taint of iov_len
  }
  return false;
}

bool is_tainted_sockaddr(const struct sockaddr * addr, tagqarr_t addr_taint, socklen_t addrlen) {
  if (is_tainted_qword(addr_taint)) return true;
  if (addr->sa_family != AF_INET) return false; // TODO: Add IPv6. For now, let's only handle IPv4.
  const struct sockaddr_in * addr_in = (const struct sockaddr_in*)addr;
  return !tag_is_empty(tagmap_getn((ADDRINT)&addr_in->sin_port, sizeof(addr_in->sin_port))) ||
         !tag_is_empty(tagmap_getn((ADDRINT)&addr_in->sin_addr, sizeof(addr_in->sin_addr)));
}

static bool is_directly_controllable_fd(int fd) {
  return fd_is_tainted(fd);
}
static bool is_indirectly_controllable_fd(tagqarr_t fd_taint) {
  return is_tainted_dword(fd_taint) && is_an_open_tainted_fd();
}
static bool is_indirectly_controllable_sockfd(tagqarr_t fd_taint) {
  return is_tainted_dword(fd_taint) && is_an_open_tainted_sockfd();
}
bool is_controllable_fd(int fd, tagqarr_t fd_taint) {
  return is_directly_controllable_fd(fd) || is_indirectly_controllable_fd(fd_taint);
}
bool is_controllable_sockfd(int sockfd, tagqarr_t fd_taint) {
  // Return true if (this sockfd is directly-controllable) OR (its tainted and there exists a controllable sockfd)
  return is_directly_controllable_fd(sockfd) || is_indirectly_controllable_sockfd(fd_taint);
}