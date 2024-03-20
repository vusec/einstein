#include "einstein_common.h"
#include "einstein_utils.h"

#define BT_MAX_DETPH 2147483647

// =====================================================================
// General utilities
// =====================================================================

string str_to_json_str(string s) {
  string jsonstr = str_replace(s, "\\", "\\\\"); /* Replace: \ with \\ */
  jsonstr = str_replace(jsonstr, "\"", "\\\""); // Replace: " with \"
  std::replace_if(jsonstr.begin(), jsonstr.end(), [](auto ch) {return !::isprint(ch);}, '.'); // Replace: Non-printable characters with .
  return jsonstr;
}

std::string str_replace(std::string str, std::string substr1, std::string substr2) {
  for (size_t index = str.find(substr1, 0); index != std::string::npos && substr1.length(); index = str.find(substr1, index + substr2.length() ) )
    str.replace(index, substr1.length(), substr2);
  return str;
}

void concat_str_set(string * curr, string next) {
  if (*curr == "{") *curr += next;
  else *curr += ", " + next;
}

string byte_to_string(uint8_t b, bool in_hex) {
  char hex_str[10];
  if (in_hex) sprintf(hex_str, "0x%02x", b);
  else sprintf(hex_str, "%u", b);
  return string(hex_str);
}

string ptr_to_string(const void * ptr, bool in_hex) {
  char hex_str[20];
  if (in_hex) sprintf(hex_str, "%p", ptr);
  else sprintf(hex_str, "%llu", (unsigned long long) ptr);
  return string(hex_str);
}

bool str_has_ending(std::string const &fullString, std::string const &ending) {
  if (fullString.length() >= ending.length()) return (0 == fullString.compare (fullString.length() - ending.length(), ending.length(), ending));
  return false;
}

// =====================================================================
// Pin/libdft utilities
// =====================================================================

bool str_data_is_tainted(const char * ptr) {
  size_t size = strlen(ptr);
  return !tag_is_empty(tagmap_getn((ADDRINT) ptr, size));
}

bool str_arr_data_is_tainted(const char ** str_arr_p) {
  if (str_arr_p == NULL || str_arr_p[0] == NULL) return false;
  for (int i = 0; str_arr_p[i] != NULL; i++) {
    if (str_data_is_tainted(str_arr_p[i])) return true;
  }
  return false;
}

static string char_taint_to_string(const char * ptr) {
  return string("'") + *ptr + "' => " + tag_sprint(tagmap_getb((ADDRINT)ptr));
}

string str_taint_to_string(const char * ptr) {
  size_t size = strlen(ptr);
  if (size == 0) return "[]";
  if (!str_data_is_tainted(ptr)) return "(untainted)";
  string s = "[" + char_taint_to_string(&ptr[0]);
  for (size_t i = 1; i < size; i++) {
    s += ", " + char_taint_to_string(&ptr[i]);
  }
  s += "]";
  return s;
}

string path_remove_root(string path) {
  // If ROOT exists in the path, replace it with an empty string
  if (path.find(ROOT) != string::npos) path.replace(path.find(ROOT), string(ROOT).length(), "");
  return path;
}

string bt_str_withlimit(const CONTEXT * ctx, bool with_symbols, bool in_hex, int bt_max_depth) {
  void* buf[128];
  std::stringstream ss;
  PIN_LockClient();
  int nptrs = PIN_Backtrace(ctx, buf, sizeof(buf)/sizeof(buf[0]));
  ASSERTX(nptrs > 0);

  if (nptrs == 0) {
    return "[]";
  }

  if (with_symbols) {
    char** bt = backtrace_symbols(buf, nptrs);
    PIN_UnlockClient();
    ASSERTX(NULL != bt);
    ss << "[\"" << bt[0];
    for (int i = 1; i < nptrs && i < bt_max_depth; i++) {
      ss << "\", \"" << bt[i];
    }
    ss << "\"]";
    free(bt);
  }

  else {
    PIN_UnlockClient();
    if (in_hex) ss << "[" << buf[0];
    else ss << "[" << std::dec << (unsigned long long) buf[0];
    for (int i = 1; i < nptrs && i < bt_max_depth; i++) {
      if (in_hex) ss << ", " << buf[i];
      else ss << ", " << std::dec << (unsigned long long) buf[i];
    }
    ss << "]";
  }

  return ss.str();
}
string bt_str(const CONTEXT * ctx, bool with_symbols, bool in_hex) {
  return bt_str_withlimit(ctx, with_symbols, in_hex, BT_MAX_DETPH);
}

// Assumes that exp_bt is a backtrace with symbols
bool bt_equals(const CONTEXT * ctx, std::vector<string> exp_bt) {
  void* buf[128];

  PIN_LockClient();
  int nptrs = PIN_Backtrace(ctx, buf, sizeof(buf)/sizeof(buf[0]));
  ASSERTX(nptrs > 0);

  if (nptrs != (int)exp_bt.size()) return false;

  char** this_bt = backtrace_symbols(buf, nptrs);
  PIN_UnlockClient();
  ASSERTX(NULL != this_bt);

  for (int i = 0; i < nptrs && i < BT_MAX_DETPH; i++) {
    if (string(exp_bt[i]) != exp_bt[i]) return false;
  }
  free(this_bt);
  return true;
}

string cptr_to_symbol(void * cptr) {
  PIN_LockClient();
  char** bt = backtrace_symbols(&cptr, 1);
  PIN_UnlockClient();
  ASSERTX(NULL != bt);
  string s = string(bt[0]);
  free(bt);
  return s;
}

string src_loc(ADDRINT rip) {
  string filename, srcname;
  INT32 line, col;
  PIN_LockClient();
  PIN_GetSourceLocation(rip, &col, &line, &filename);
  PIN_UnlockClient();
  if (filename == "") srcname = "?:?:?";
  else srcname = path_remove_root(filename) + ":" + my_to_string(line) + ":" + my_to_string(col);
  string funcname = PIN_UndecorateSymbolName(RTN_FindNameByAddress(rip),UNDECORATION_NAME_ONLY);
  return srcname + ":" + funcname;
}

// =====================================================================
// Syscall utilities (helpers)
// =====================================================================

static string prot_to_str(unsigned long prot) {
  if (prot == PROT_NONE) return "{PROT_NONE}";
  string prot_s = "{";
  if (prot & PROT_READ) concat_str_set(&prot_s, "PROT_READ");
  if (prot & PROT_WRITE) concat_str_set(&prot_s, "PROT_WRITE");
  if (prot & PROT_EXEC) concat_str_set(&prot_s, "PROT_EXEC");
  if (prot & PROT_SEM) concat_str_set(&prot_s, "PROT_SEM");
  if (prot & PROT_GROWSUP) concat_str_set(&prot_s, "PROT_GROWSUP");
  if (prot & PROT_GROWSDOWN) concat_str_set(&prot_s, "PROT_GROWSDOWN");
  return prot_s + "}";
}

static string fd_to_net(unsigned long fd) {
  // Warning: Janky
  string cmd = "lsof -w -p " + my_to_string(PIN_GetPid()) + " -a -d " + my_to_string(fd) + " -a -FnPt | " +
                "tail -n +3 | sed 's/^t/type = /; s/^n/name = /; s/^P/protocol = /' | " +
                "tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g'";
  string result = "{";
  char buffer[1024];

  FILE* pipe = popen(cmd.c_str(), "r");
  if (!pipe) return "(ERR)";
  while (fgets(buffer, 1024, pipe) != NULL) result += string(buffer);
  result += "}";
  pclose(pipe);

  return result;
}

static string fd_to_str(unsigned long fd) {
  char filename[300] = {0}, procname[300] = {0};
  sprintf(procname, "/proc/self/fd/%lu", fd);
  if (readlink(procname, filename, 300) < 0) return "(ERR)";
  string name = path_remove_root(string(filename));
  if (name.find("socket:[") != string::npos) name = fd_to_net(fd);
  return name;
}

static string open_files_to_str(void) {
  return "(skipped)";
  /*
  DIR *dir;
  struct dirent *ent;
  string fs = "{";

  if ((dir = opendir("/proc/self/fd/")) == NULL) return "(ERR)"; // Could not open directory

  // For all files in the "/proc/self/fd/" directory
  while ((ent = readdir(dir)) != NULL) {
    if (ent->d_type == DT_DIR) continue; // Skip directories (e.g., "." and "..")
    unsigned long fd = atol(ent->d_name);
    string name = fd_to_str(fd);

    // Don't include libdft/Einstein/etc. logs, or /dev/null
    if (name.find("/libdft.") != string::npos || name.find("/einstein.") != string::npos ||
        name.find("/dbt.cmd") != string::npos || name == "/dev/null") continue;

    concat_str_set(&fs, my_to_string(fd) + " => " + name);
  }

  closedir (dir);
  return fs + "}";
  */
}

// =====================================================================
// Syscall utilities
// =====================================================================

string fd_info_old(unsigned long fd, tag_t fd_taint) {
  string s = fd_to_str(fd);
  if (!tag_is_empty(fd_taint)) s += ", all_open_fds = " + open_files_to_str();
  return s;
}

string str_info(const char * str_p, bool verbose) {
  string s = ptr_to_string(str_p, false) + " = \"" + string(str_p) + "\"";
  // TODO: Add call to path_remove_root() back in?
  if (verbose) s += " => " + str_taint_to_string(str_p);
  return s;
}

string str_arr_info(const char ** str_arr_p, bool verbose) {
  if (str_arr_p == NULL || str_arr_p[0] == NULL) return "(empty)";
  string s = "[" + str_info(str_arr_p[0], verbose);
  for (int i = 1; str_arr_p[i] != NULL; i++) {
    s += ", " + str_info(str_arr_p[i], verbose);
  }
  s += "]";
  return s;
}

string char_ptr_info(ADDRINT buf_pa, tag_t buf_p_taint, size_t count) {
  const char * buf_p = (const char *) buf_pa;
  if (count >= 1024) return "(too large)";
  if (buf_p == NULL) return "(bad ptr)"; // TODO: Either check this after the syscall (and see if it returned an error) or check other possible "bad ptrs"
  return "(skipped)";
  /*
  string s;
  for (unsigned int i = 0; i < count; i++) {
    char c = buf_p[i];
    if (c == 0) break;
    if (!isprint(c)) return s += "(not printable)";
    s += c;
  }
  return s;
  */
}

string prot_info(unsigned long prot) {
  return "prot = " + prot_to_str(prot);
}

bool flags_is_writable(int flags) {
  return ((flags & 3) == O_WRONLY) |
         ((flags & 3) == O_RDWR);
}

string flags_to_str(int flags) {
  string s = "{";
  // Access modes
  if ((flags & 3) == O_RDONLY) s += "O_RDONLY";
  else if ((flags & 3) == O_WRONLY) s += "O_WRONLY";
  else if ((flags & 3) == O_RDWR) s += "O_RDWR";
  // File creation and file status flags
  if (flags & O_APPEND) s += "|O_APPEND";
  //if (flags & O_ASYNC) s += "|O_ASYNC";
  if (flags & O_CLOEXEC) s += "|O_CLOEXEC";
  if (flags & O_CREAT) s += "|O_CREAT";
  if (flags & O_DIRECT) s += "|O_DIRECT";
  if (flags & O_DIRECTORY) s += "|O_DIRECTORY";
  if (flags & O_DSYNC) s += "|O_DSYNC";
  if (flags & O_EXCL) s += "|O_EXCL";
  if (flags & O_LARGEFILE) s += "|O_LARGEFILE";
  if (flags & O_NOATIME) s += "|O_NOATIME";
  if (flags & O_NOCTTY) s += "|O_NOCTTY";
  if (flags & O_NOFOLLOW) s += "|O_NOFOLLOW";
  if (flags & O_NONBLOCK) s += "|O_NONBLOCK";
  if (flags & O_PATH) s += "|O_PATH";
  if (flags & O_SYNC) s += "|O_SYNC";
  if (flags & O_TMPFILE) s += "|O_TMPFILE";
  if (flags & O_TRUNC) s += "|O_TRUNC";
  s += "}";
  return s;
}

#define SYS_NAME_CHECK(this_name) if (syscall_name == #this_name) return __NR_ ## this_name;
unsigned long syscall_name_to_nr(string syscall_name) {
  SYS_NAME_CHECK(read);
  SYS_NAME_CHECK(write);
  SYS_NAME_CHECK(open);
  SYS_NAME_CHECK(close);
  SYS_NAME_CHECK(stat);
  SYS_NAME_CHECK(fstat);
  SYS_NAME_CHECK(lstat);
  SYS_NAME_CHECK(poll);
  SYS_NAME_CHECK(lseek);
  SYS_NAME_CHECK(mmap);
  SYS_NAME_CHECK(mprotect);
  SYS_NAME_CHECK(munmap);
  SYS_NAME_CHECK(brk);
  SYS_NAME_CHECK(rt_sigaction);
  SYS_NAME_CHECK(rt_sigprocmask);
  SYS_NAME_CHECK(rt_sigreturn);
  SYS_NAME_CHECK(ioctl);
  SYS_NAME_CHECK(pread64);
  SYS_NAME_CHECK(pwrite64);
  SYS_NAME_CHECK(readv);
  SYS_NAME_CHECK(writev);
  SYS_NAME_CHECK(access);
  SYS_NAME_CHECK(pipe);
  SYS_NAME_CHECK(select);
  SYS_NAME_CHECK(sched_yield);
  SYS_NAME_CHECK(mremap);
  SYS_NAME_CHECK(msync);
  SYS_NAME_CHECK(mincore);
  SYS_NAME_CHECK(madvise);
  SYS_NAME_CHECK(shmget);
  SYS_NAME_CHECK(shmat);
  SYS_NAME_CHECK(shmctl);
  SYS_NAME_CHECK(dup);
  SYS_NAME_CHECK(dup2);
  SYS_NAME_CHECK(pause);
  SYS_NAME_CHECK(nanosleep);
  SYS_NAME_CHECK(getitimer);
  SYS_NAME_CHECK(alarm);
  SYS_NAME_CHECK(setitimer);
  SYS_NAME_CHECK(getpid);
  SYS_NAME_CHECK(sendfile);
  SYS_NAME_CHECK(socket);
  SYS_NAME_CHECK(connect);
  SYS_NAME_CHECK(accept);
  SYS_NAME_CHECK(sendto);
  SYS_NAME_CHECK(recvfrom);
  SYS_NAME_CHECK(sendmsg);
  SYS_NAME_CHECK(recvmsg);
  SYS_NAME_CHECK(shutdown);
  SYS_NAME_CHECK(bind);
  SYS_NAME_CHECK(listen);
  SYS_NAME_CHECK(getsockname);
  SYS_NAME_CHECK(getpeername);
  SYS_NAME_CHECK(socketpair);
  SYS_NAME_CHECK(setsockopt);
  SYS_NAME_CHECK(getsockopt);
  SYS_NAME_CHECK(clone);
  SYS_NAME_CHECK(fork);
  SYS_NAME_CHECK(vfork);
  SYS_NAME_CHECK(execve);
  SYS_NAME_CHECK(exit);
  SYS_NAME_CHECK(wait4);
  SYS_NAME_CHECK(kill);
  SYS_NAME_CHECK(uname);
  SYS_NAME_CHECK(semget);
  SYS_NAME_CHECK(semop);
  SYS_NAME_CHECK(semctl);
  SYS_NAME_CHECK(shmdt);
  SYS_NAME_CHECK(msgget);
  SYS_NAME_CHECK(msgsnd);
  SYS_NAME_CHECK(msgrcv);
  SYS_NAME_CHECK(msgctl);
  SYS_NAME_CHECK(fcntl);
  SYS_NAME_CHECK(flock);
  SYS_NAME_CHECK(fsync);
  SYS_NAME_CHECK(fdatasync);
  SYS_NAME_CHECK(truncate);
  SYS_NAME_CHECK(ftruncate);
  SYS_NAME_CHECK(getdents);
  SYS_NAME_CHECK(getcwd);
  SYS_NAME_CHECK(chdir);
  SYS_NAME_CHECK(fchdir);
  SYS_NAME_CHECK(rename);
  SYS_NAME_CHECK(mkdir);
  SYS_NAME_CHECK(rmdir);
  SYS_NAME_CHECK(creat);
  SYS_NAME_CHECK(link);
  SYS_NAME_CHECK(unlink);
  SYS_NAME_CHECK(symlink);
  SYS_NAME_CHECK(readlink);
  SYS_NAME_CHECK(chmod);
  SYS_NAME_CHECK(fchmod);
  SYS_NAME_CHECK(chown);
  SYS_NAME_CHECK(fchown);
  SYS_NAME_CHECK(lchown);
  SYS_NAME_CHECK(umask);
  SYS_NAME_CHECK(gettimeofday);
  SYS_NAME_CHECK(getrlimit);
  SYS_NAME_CHECK(getrusage);
  SYS_NAME_CHECK(sysinfo);
  SYS_NAME_CHECK(times);
  SYS_NAME_CHECK(ptrace);
  SYS_NAME_CHECK(getuid);
  SYS_NAME_CHECK(syslog);
  SYS_NAME_CHECK(getgid);
  SYS_NAME_CHECK(setuid);
  SYS_NAME_CHECK(setgid);
  SYS_NAME_CHECK(geteuid);
  SYS_NAME_CHECK(getegid);
  SYS_NAME_CHECK(setpgid);
  SYS_NAME_CHECK(getppid);
  SYS_NAME_CHECK(getpgrp);
  SYS_NAME_CHECK(setsid);
  SYS_NAME_CHECK(setreuid);
  SYS_NAME_CHECK(setregid);
  SYS_NAME_CHECK(getgroups);
  SYS_NAME_CHECK(setgroups);
  SYS_NAME_CHECK(setresuid);
  SYS_NAME_CHECK(getresuid);
  SYS_NAME_CHECK(setresgid);
  SYS_NAME_CHECK(getresgid);
  SYS_NAME_CHECK(getpgid);
  SYS_NAME_CHECK(setfsuid);
  SYS_NAME_CHECK(setfsgid);
  SYS_NAME_CHECK(getsid);
  SYS_NAME_CHECK(capget);
  SYS_NAME_CHECK(capset);
  SYS_NAME_CHECK(rt_sigpending);
  SYS_NAME_CHECK(rt_sigtimedwait);
  SYS_NAME_CHECK(rt_sigqueueinfo);
  SYS_NAME_CHECK(rt_sigsuspend);
  SYS_NAME_CHECK(sigaltstack);
  SYS_NAME_CHECK(utime);
  SYS_NAME_CHECK(mknod);
  SYS_NAME_CHECK(uselib);
  SYS_NAME_CHECK(personality);
  SYS_NAME_CHECK(ustat);
  SYS_NAME_CHECK(statfs);
  SYS_NAME_CHECK(fstatfs);
  SYS_NAME_CHECK(sysfs);
  SYS_NAME_CHECK(getpriority);
  SYS_NAME_CHECK(setpriority);
  SYS_NAME_CHECK(sched_setparam);
  SYS_NAME_CHECK(sched_getparam);
  SYS_NAME_CHECK(sched_setscheduler);
  SYS_NAME_CHECK(sched_getscheduler);
  SYS_NAME_CHECK(sched_get_priority_max);
  SYS_NAME_CHECK(sched_get_priority_min);
  SYS_NAME_CHECK(sched_rr_get_interval);
  SYS_NAME_CHECK(mlock);
  SYS_NAME_CHECK(munlock);
  SYS_NAME_CHECK(mlockall);
  SYS_NAME_CHECK(munlockall);
  SYS_NAME_CHECK(vhangup);
  SYS_NAME_CHECK(modify_ldt);
  SYS_NAME_CHECK(pivot_root);
  SYS_NAME_CHECK(_sysctl);
  SYS_NAME_CHECK(prctl);
  SYS_NAME_CHECK(arch_prctl);
  SYS_NAME_CHECK(adjtimex);
  SYS_NAME_CHECK(setrlimit);
  SYS_NAME_CHECK(chroot);
  SYS_NAME_CHECK(sync);
  SYS_NAME_CHECK(acct);
  SYS_NAME_CHECK(settimeofday);
  SYS_NAME_CHECK(mount);
  SYS_NAME_CHECK(umount2);
  SYS_NAME_CHECK(swapon);
  SYS_NAME_CHECK(swapoff);
  SYS_NAME_CHECK(reboot);
  SYS_NAME_CHECK(sethostname);
  SYS_NAME_CHECK(setdomainname);
  SYS_NAME_CHECK(iopl);
  SYS_NAME_CHECK(ioperm);
  SYS_NAME_CHECK(create_module);
  SYS_NAME_CHECK(init_module);
  SYS_NAME_CHECK(delete_module);
  SYS_NAME_CHECK(get_kernel_syms);
  SYS_NAME_CHECK(query_module);
  SYS_NAME_CHECK(quotactl);
  SYS_NAME_CHECK(nfsservctl);
  SYS_NAME_CHECK(getpmsg);
  SYS_NAME_CHECK(putpmsg);
  SYS_NAME_CHECK(afs_syscall);
  SYS_NAME_CHECK(tuxcall);
  SYS_NAME_CHECK(security);
  SYS_NAME_CHECK(gettid);
  SYS_NAME_CHECK(readahead);
  SYS_NAME_CHECK(setxattr);
  SYS_NAME_CHECK(lsetxattr);
  SYS_NAME_CHECK(fsetxattr);
  SYS_NAME_CHECK(getxattr);
  SYS_NAME_CHECK(lgetxattr);
  SYS_NAME_CHECK(fgetxattr);
  SYS_NAME_CHECK(listxattr);
  SYS_NAME_CHECK(llistxattr);
  SYS_NAME_CHECK(flistxattr);
  SYS_NAME_CHECK(removexattr);
  SYS_NAME_CHECK(lremovexattr);
  SYS_NAME_CHECK(fremovexattr);
  SYS_NAME_CHECK(tkill);
  SYS_NAME_CHECK(time);
  SYS_NAME_CHECK(futex);
  SYS_NAME_CHECK(sched_setaffinity);
  SYS_NAME_CHECK(sched_getaffinity);
  SYS_NAME_CHECK(set_thread_area);
  SYS_NAME_CHECK(io_setup);
  SYS_NAME_CHECK(io_destroy);
  SYS_NAME_CHECK(io_getevents);
  SYS_NAME_CHECK(io_submit);
  SYS_NAME_CHECK(io_cancel);
  SYS_NAME_CHECK(get_thread_area);
  SYS_NAME_CHECK(lookup_dcookie);
  SYS_NAME_CHECK(epoll_create);
  SYS_NAME_CHECK(epoll_ctl_old);
  SYS_NAME_CHECK(epoll_wait_old);
  SYS_NAME_CHECK(remap_file_pages);
  SYS_NAME_CHECK(getdents64);
  SYS_NAME_CHECK(set_tid_address);
  SYS_NAME_CHECK(restart_syscall);
  SYS_NAME_CHECK(semtimedop);
  SYS_NAME_CHECK(fadvise64);
  SYS_NAME_CHECK(timer_create);
  SYS_NAME_CHECK(timer_settime);
  SYS_NAME_CHECK(timer_gettime);
  SYS_NAME_CHECK(timer_getoverrun);
  SYS_NAME_CHECK(timer_delete);
  SYS_NAME_CHECK(clock_settime);
  SYS_NAME_CHECK(clock_gettime);
  SYS_NAME_CHECK(clock_getres);
  SYS_NAME_CHECK(clock_nanosleep);
  SYS_NAME_CHECK(exit_group);
  SYS_NAME_CHECK(epoll_wait);
  SYS_NAME_CHECK(epoll_ctl);
  SYS_NAME_CHECK(tgkill);
  SYS_NAME_CHECK(utimes);
  SYS_NAME_CHECK(vserver);
  SYS_NAME_CHECK(mbind);
  SYS_NAME_CHECK(set_mempolicy);
  SYS_NAME_CHECK(get_mempolicy);
  SYS_NAME_CHECK(mq_open);
  SYS_NAME_CHECK(mq_unlink);
  SYS_NAME_CHECK(mq_timedsend);
  SYS_NAME_CHECK(mq_timedreceive);
  SYS_NAME_CHECK(mq_notify);
  SYS_NAME_CHECK(mq_getsetattr);
  SYS_NAME_CHECK(kexec_load);
  SYS_NAME_CHECK(waitid);
  SYS_NAME_CHECK(add_key);
  SYS_NAME_CHECK(request_key);
  SYS_NAME_CHECK(keyctl);
  SYS_NAME_CHECK(ioprio_set);
  SYS_NAME_CHECK(ioprio_get);
  SYS_NAME_CHECK(inotify_init);
  SYS_NAME_CHECK(inotify_add_watch);
  SYS_NAME_CHECK(inotify_rm_watch);
  SYS_NAME_CHECK(migrate_pages);
  SYS_NAME_CHECK(openat);
  SYS_NAME_CHECK(mkdirat);
  SYS_NAME_CHECK(mknodat);
  SYS_NAME_CHECK(fchownat);
  SYS_NAME_CHECK(futimesat);
  SYS_NAME_CHECK(newfstatat);
  SYS_NAME_CHECK(unlinkat);
  SYS_NAME_CHECK(renameat);
  SYS_NAME_CHECK(linkat);
  SYS_NAME_CHECK(symlinkat);
  SYS_NAME_CHECK(readlinkat);
  SYS_NAME_CHECK(fchmodat);
  SYS_NAME_CHECK(faccessat);
  SYS_NAME_CHECK(pselect6);
  SYS_NAME_CHECK(ppoll);
  SYS_NAME_CHECK(unshare);
  SYS_NAME_CHECK(set_robust_list);
  SYS_NAME_CHECK(get_robust_list);
  SYS_NAME_CHECK(splice);
  SYS_NAME_CHECK(tee);
  SYS_NAME_CHECK(sync_file_range);
  SYS_NAME_CHECK(vmsplice);
  SYS_NAME_CHECK(move_pages);
  SYS_NAME_CHECK(utimensat);
  SYS_NAME_CHECK(epoll_pwait);
  SYS_NAME_CHECK(signalfd);
  SYS_NAME_CHECK(timerfd_create);
  SYS_NAME_CHECK(eventfd);
  SYS_NAME_CHECK(fallocate);
  SYS_NAME_CHECK(timerfd_settime);
  SYS_NAME_CHECK(timerfd_gettime);
  SYS_NAME_CHECK(accept4);
  SYS_NAME_CHECK(signalfd4);
  SYS_NAME_CHECK(eventfd2);
  SYS_NAME_CHECK(epoll_create1);
  SYS_NAME_CHECK(dup3);
  SYS_NAME_CHECK(pipe2);
  SYS_NAME_CHECK(inotify_init1);
  SYS_NAME_CHECK(preadv);
  SYS_NAME_CHECK(pwritev);
  SYS_NAME_CHECK(rt_tgsigqueueinfo);
  SYS_NAME_CHECK(perf_event_open);
  SYS_NAME_CHECK(recvmmsg);
  SYS_NAME_CHECK(fanotify_init);
  SYS_NAME_CHECK(fanotify_mark);
  SYS_NAME_CHECK(prlimit64);
  SYS_NAME_CHECK(name_to_handle_at);
  SYS_NAME_CHECK(open_by_handle_at);
  SYS_NAME_CHECK(clock_adjtime);
  SYS_NAME_CHECK(syncfs);
  SYS_NAME_CHECK(sendmmsg);
  SYS_NAME_CHECK(setns);
  SYS_NAME_CHECK(getcpu);
  SYS_NAME_CHECK(process_vm_readv);
  SYS_NAME_CHECK(process_vm_writev);
  SYS_NAME_CHECK(kcmp);
  SYS_NAME_CHECK(finit_module);
  SYS_NAME_CHECK(sched_setattr);
  SYS_NAME_CHECK(sched_getattr);
  // Below syscalls technically not supported by Pin 3.24
  SYS_NAME_CHECK(renameat2);
  SYS_NAME_CHECK(seccomp);
  SYS_NAME_CHECK(getrandom);
  SYS_NAME_CHECK(memfd_create);
  SYS_NAME_CHECK(kexec_file_load);
  SYS_NAME_CHECK(bpf);
  SYS_NAME_CHECK(execveat);
  SYS_NAME_CHECK(userfaultfd);
  SYS_NAME_CHECK(membarrier);
  SYS_NAME_CHECK(mlock2);
  SYS_NAME_CHECK(copy_file_range);
  SYS_NAME_CHECK(preadv2);
  SYS_NAME_CHECK(pwritev2);
  SYS_NAME_CHECK(pkey_mprotect);
  SYS_NAME_CHECK(pkey_alloc);
  SYS_NAME_CHECK(pkey_free);
  SYS_NAME_CHECK(statx);
  SYS_NAME_CHECK(io_pgetevents);
  SYS_NAME_CHECK(rseq);
  // Gap from syscall numbers of rseq (334) to pidfd_send_signal (424)
  SYS_NAME_CHECK(pidfd_send_signal);
  SYS_NAME_CHECK(io_uring_setup);
  SYS_NAME_CHECK(io_uring_enter);
  SYS_NAME_CHECK(io_uring_register);
  SYS_NAME_CHECK(open_tree);
  SYS_NAME_CHECK(move_mount);
  SYS_NAME_CHECK(fsopen);
  SYS_NAME_CHECK(fsconfig);
  SYS_NAME_CHECK(fsmount);
  SYS_NAME_CHECK(fspick);
  SYS_NAME_CHECK(pidfd_open);
  SYS_NAME_CHECK(clone3);
  SYS_NAME_CHECK(close_range);
  SYS_NAME_CHECK(openat2);
  SYS_NAME_CHECK(pidfd_getfd);
  SYS_NAME_CHECK(faccessat2);
  SYS_NAME_CHECK(process_madvise);
  SYS_NAME_CHECK(epoll_pwait2);
  SYS_NAME_CHECK(mount_setattr);
  SYS_NAME_CHECK(quotactl_fd);
  SYS_NAME_CHECK(landlock_create_ruleset);
  SYS_NAME_CHECK(landlock_add_rule);
  SYS_NAME_CHECK(landlock_restrict_self);
  SYS_NAME_CHECK(memfd_secret);
  SYS_NAME_CHECK(process_mrelease);
  EINSTEIN_EXIT("%s:%d: Error: Unsupported translation from syscall name ('%s') to number\n", __FILE__, __LINE__, syscall_name.c_str());
}