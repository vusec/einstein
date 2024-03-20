#ifndef EINSTEIN_COMMON_H
#define EINSTEIN_COMMON_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <execinfo.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <unordered_map>
#include <set>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <arpa/inet.h>
#include "pin.H"
#include "libdft_api.h"
#include "ins_helper.h"
#include "syscall_desc.h"
#include "memtaint.h"
using std::string;

#ifndef ROOT
#error Please define ROOT
#endif

#ifndef LIBDFT_TAG_PTR
#error Please define LIBDFT_TAG_PTR
#endif

#ifndef LIBDFT_PTR_32
#error Please define LIBDFT_PTR_32
#endif

// Limit strings to 128 bytes, because that's long enough to fit our reverse shellcode
#define MAX_PCHAR_LEN 128

// Limit string arrays to 5 strings, because that's enough to fit our reverse shellcode (3 strings min)
#define MAX_PPCHAR_LEN 5
#define MAX_IOVEC_LEN 5

#define EINSTEIN_LOG(...)                 \
  do {                               \
    if (_einstein_use_log) {              \
      _einstein_log->lock();           \
      _einstein_log->log(__VA_ARGS__); \
      _einstein_log->unlock();         \
    } else {                         \
      fprintf(stdout, __VA_ARGS__);  \
      fflush(stdout);                \
  }} while (0)

#define EINSTEIN_LOG_DEBUG() EINSTEIN_LOG("%s:%d\n",__FILE__,__LINE__)

#define EINSTEIN_EXIT(...)     \
  do {                    \
    EINSTEIN_LOG(__VA_ARGS__); \
    exit(1);              \
  } while (0)

#define EINSTEIN_EXIT_UNREACHABLE() EINSTEIN_EXIT("%s:%d: Error: Should not reach this line.\n",__FILE__,__LINE__)

extern PinLog *_einstein_log;
extern bool _einstein_use_log;

extern string application_name;

#endif
