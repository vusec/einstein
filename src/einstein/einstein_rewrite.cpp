#include "einstein_common.h"
#include "einstein_syscalls.h"
#include "einstein_utils.h"
#include "picojson.h"

// =====================================================================
// Data
// =====================================================================

#define REWRITE_EVAL_FINISHED_STR "REWRITE_EVAL_FINISHED"
#define EVAL_MATCH_LEN 4
#define EVAL_MATCH_LEN_MAX 16

struct einstein_rewrite {
  /* Identifier */
  string type;
  string application;
  std::vector<string> backtrace;
  string syscall;
  uint8_t syscall_arg_num;
  /* Rewrite info */
  uint8_t * address;
  std::vector<uint8_t> expected_vals;
  size_t ptr_depth;
  size_t write_vuln_count;
  /* Flags that start out false, then are set to true during execution */
  bool rewrite_performed;
  bool rewrite_verified;

  einstein_rewrite(picojson::value config_rewrite) {
    type = config_rewrite.get("type").get<string>();
    application = config_rewrite.get("application").get<string>();

    picojson::array config_backtrace = config_rewrite.get("backtrace").get<picojson::array>();
    for (size_t i = 0; i < config_backtrace.size(); i++) backtrace.push_back(config_backtrace[i].get<string>());

    syscall = config_rewrite.get("syscall").get<string>();
    syscall_arg_num = config_rewrite.get("syscall_arg_num").get<double>();
    address = (uint8_t*)((uint64_t)config_rewrite.get("address").get<double>()); // We apparently have to cast from double -> uint64_t -> uint8_t *

    picojson::array config_expvals = config_rewrite.get("expected_vals").get<picojson::array>();
    for (size_t i = 0; i < config_expvals.size(); i++) expected_vals.push_back(config_expvals[i].get<double>());

    ptr_depth = config_rewrite.get("ptr_depth").get<double>();
    write_vuln_count = config_rewrite.get("write_vuln_count").get<double>();

    rewrite_performed = false;
    rewrite_verified = false;
  }

  string to_str() {
    string backtrace_str = backtrace.size() > 0 ? "[\"" + backtrace[0] + "\"" : "";
    for (size_t i = 1; i < backtrace.size(); i++) backtrace_str += ", \"" + backtrace[i] + "\"";
    backtrace_str += "]";

    string expected_vals_str = expected_vals.size() > 0 ? "[" + byte_to_string(expected_vals[0], true) : "";
    for (size_t i = 1; i < expected_vals.size(); i++) expected_vals_str += ", " + byte_to_string(expected_vals[i], true);
    expected_vals_str += "]";

    return "{type = '" + type + "', " +
            "application = '" + application + "', " +
            /*"backtrace = " + backtrace_str + + ", " +*/
            "syscall = '" + syscall + "', " +
            "syscall_arg_num = " + std::to_string(syscall_arg_num) + ", " +
            "address = " + ptr_to_string(address, true) + ", " +
            "expected_vals = " + expected_vals_str + ", " +
            "ptr_depth = " + std::to_string(ptr_depth) + ", "
            "write_vuln_count = " + std::to_string(write_vuln_count) + ", "
            "rewrite_performed = " + std::to_string(rewrite_performed) + ", " +
            "rewrite_verified = " + std::to_string(rewrite_verified) + "}";
  }
};

static std::vector<einstein_rewrite> rewrites_list;

bool do_rewrites = false;

// =====================================================================
// Rewrite check
// =====================================================================
// ======== Helpers ========
bool einstein_rewrite_check_buf(void * target_ptr, size_t target_len, const void * canary_data, size_t canary_len) {
  canary_len = MIN(canary_len, EVAL_MATCH_LEN);
  for (size_t i = 0; canary_len + i <= target_len; i++) {
    if (!memcmp((uint8_t*)target_ptr+i, (uint8_t*)canary_data, canary_len)) return true;
  }
  return false;
}
bool einstein_rewrite_check_ppchar(char ** pptr, const void * canary_data, size_t canary_len) {
  if (pptr != NULL) {
    for (size_t i = 0; pptr[i] != NULL && i < MAX_PPCHAR_LEN; i++)
      if (einstein_rewrite_check_buf(pptr[i], strlen(pptr[i]) + 1, canary_data, canary_len)) return true;
  }
  return false;
}
bool einstein_rewrite_check_iovec(struct iovec *target_iov, size_t target_iovcnt, const void * canary_data, size_t canary_len) {
  if (target_iov != NULL) {
    for (size_t i = 0; target_iov[i].iov_base != NULL && i < MAX_IOVEC_LEN; i++)
      if (einstein_rewrite_check_buf(target_iov[i].iov_base, target_iov[i].iov_len, canary_data, canary_len)) return true;
  }
  return false;
}

// ======== Handler called from einstein_pre_syscall_hook ========
static void einstein_rewrite_check_done() {
  for (size_t i = 0; i < rewrites_list.size(); i++)
    if (!rewrites_list[i].rewrite_verified) return;
  EINSTEIN_EXIT("%s:%d: %s:SUCCESS: Successfully verified all rewrites!\n", __FILE__, __LINE__, REWRITE_EVAL_FINISHED_STR);
}

void einstein_rewrite_check(syscall_ctx_t *ctx) {
  // If this is the right syscall and the right backtrace, then check whether the arguments contain our 'exploit canaries'
  string this_backtrace = bt_str(ctx->pinctx, true, false);
  string this_syscall = einstein_syscalls[ctx->nr].name;
  for (size_t i = 0; i < rewrites_list.size(); i++) {
    einstein_rewrite * this_rewrite = &rewrites_list[i];
    if (!this_rewrite->rewrite_performed) continue;
    if (this_rewrite->syscall == this_syscall && bt_equals(ctx->pinctx, this_rewrite->backtrace)) {
      //EINSTEIN_LOG("%s:%d: Covered the syscall/backtrace of rewrite %s\n", __FILE__, __LINE__, this_rewrite->to_str().c_str());
      if (einstein_syscalls[ctx->nr].rewrite_check(ctx, this_rewrite->syscall_arg_num)) {
        this_rewrite->rewrite_verified = true;
        EINSTEIN_LOG("%s:%d: Confirmed rewrite %lu! (Rewrite: %s)\n", __FILE__, __LINE__, i, this_rewrite->to_str().c_str());
        einstein_rewrite_check_done(); // If all rewrites have been verified, exit
      }
    }
  }
}

// =====================================================================
// Rewrite initialization
// =====================================================================
// ======== Helpers ========

static void * einstein_rewrite_init_ptrs(void * target_address_in, size_t ptr_depth) {
  uint8_t * target_address = (uint8_t*)target_address_in;
  for (size_t curr_depth = ptr_depth; curr_depth > 0; curr_depth--) {
    *((uint8_t**)target_address) = (uint8_t*)malloc(MAX(EVAL_MATCH_LEN_MAX,sizeof(uint8_t*))); // Set old_ptr to our new_ptr
    target_address = *((uint8_t**)target_address); // Our new_ptr now becomes the old_ptr
  }
  return (void*)target_address;
}

void einstein_rewrite_init_buf(string type, size_t ptr_depth, void * target_address, size_t target_len, const void * canary_data, size_t canary_len) {
  target_address = einstein_rewrite_init_ptrs(target_address, ptr_depth);
  if (str_has_ending(type, "buf") || type == "qword" || type == "dword") {
    canary_len = MIN(canary_len, EVAL_MATCH_LEN);
    ASSERTX(target_len >= canary_len);
    memcpy(target_address, canary_data, canary_len);
  }
  else if (str_has_ending(type, "vptr_qword")) {
    ASSERTX(target_len >= sizeof(ADDRINT));
    void * my_buf = malloc(canary_len);
    *(void**)target_address = my_buf;
    memcpy(my_buf, canary_data, canary_len);
  }
  else if (type == "ppchar_qword") {
    ASSERTX(target_len >= sizeof(ADDRINT));
    char * my_buf = (char*)malloc(canary_len);
    char ** my_ptrs = (char**)malloc(sizeof(char*)*2);
    *(char***)target_address = my_ptrs;
    my_ptrs[0] = my_buf;
    my_ptrs[1] = NULL;
    memcpy(my_buf, canary_data, canary_len);
  }
  else if (type == "iovec_qword") {
    ASSERTX(target_len >= sizeof(ADDRINT));
    // Allocate a buffer to put the canary, and an iovec array
    void * my_iov_base = (char *)malloc(canary_len);
    struct iovec * my_iov = (struct iovec *)malloc(sizeof(struct iovec)*MAX_IOVEC_LEN);
    // Copy the canary into our buffer, and initialize all of the iovecs with this
    memcpy(my_iov_base, canary_data, canary_len);
    for (size_t i = 0; i < MAX_IOVEC_LEN; i++) {
      my_iov[i].iov_base = my_iov_base;
      my_iov[i].iov_len = canary_len;
    }
    // Overwrite the target data to point to our iovec array
    *(struct iovec **)target_address = my_iov;
  }
  else {
    EINSTEIN_EXIT("%s:%d: Error: Unhandled rewrite type '%s'\n", __FILE__, __LINE__, type.c_str());
  }
}

static uint8_t * einstein_rewrite_follow_ptrs(uint8_t * ptr, size_t ptr_depth) {
  EINSTEIN_LOG("%s:%d: Following pointer %p to depth %lu...\n", __FILE__, __LINE__, ptr, ptr_depth);
  for (size_t curr_depth = ptr_depth; curr_depth > 0; curr_depth--) ptr = *((uint8_t**) ptr);
  EINSTEIN_LOG("%s:%d: Done following pointer. Got: %p.\n", __FILE__, __LINE__, ptr);
  return ptr;
}

// ======== Handler called from memtaint ========
static size_t rewrite_init_count = 0;

void einstein_rewrite_init(void) {
  rewrite_init_count++;
  if (!do_rewrites) return;
  EINSTEIN_LOG("%s:%d: Starting memtaint callback (rewrite_init_count = %lu)...\n", __FILE__, __LINE__, rewrite_init_count);
  for (size_t i = 0; i < rewrites_list.size(); i++) {
      einstein_rewrite * this_rewrite = &rewrites_list[i];

      // Sanity check that we're rewriting on the correct application
      if (this_rewrite->application != application_name) EINSTEIN_EXIT("Error: Attempting rewrite for application '%s', but currently running application '%s'. (Rewrite: '%s').\n", this_rewrite->application.c_str(), application_name.c_str(), this_rewrite->to_str().c_str());
      if (this_rewrite->write_vuln_count != rewrite_init_count) continue; // We'll perform this rewrite another time

      EINSTEIN_LOG("%s:%d: Performing rewrite %lu: %s\n", __FILE__, __LINE__, i, this_rewrite->to_str().c_str());

      // Check that the target data is what we expect it to be
      uint8_t * base_addr = einstein_rewrite_follow_ptrs(this_rewrite->address, this_rewrite->ptr_depth);
      for (size_t j = 0; j < this_rewrite->expected_vals.size(); j++) {
        uint8_t * curr_addr = base_addr + j;
        uint8_t curr_val = *curr_addr;
        uint8_t exp_val = this_rewrite->expected_vals[j];
        if (curr_val != exp_val) EINSTEIN_EXIT("%s:%d: %s:FAIL: Not performing rewrite. Expected 0x%x at target address %p but got 0x%x. (Rewrite: '%s').\n", __FILE__, __LINE__, REWRITE_EVAL_FINISHED_STR, exp_val, curr_addr, curr_val, this_rewrite->to_str().c_str());
      }

      einstein_syscalls[syscall_name_to_nr(this_rewrite->syscall)].rewrite_init(this_rewrite->type, this_rewrite->ptr_depth, this_rewrite->syscall_arg_num, this_rewrite->address, this_rewrite->expected_vals.size());
      this_rewrite->rewrite_performed = true;
  }

  EINSTEIN_LOG("%s:%d: Done with memtaint callback\n", __FILE__, __LINE__);
}

// =====================================================================
// Rewrite config parsing (from main)
// =====================================================================

void einstein_config_parse(string path) {
  picojson::value config;
  std::ostringstream configss;
  std::ifstream configfile(path);

  // Read config file
  if (!configfile.is_open()) EINSTEIN_EXIT("Error: Unable to open config file %s\n", path.c_str());
  configss << configfile.rdbuf();
  configfile.close();

  // Parse config and check that it is a JSON object
  string err = picojson::parse(config, configss.str());
  if (!err.empty()) EINSTEIN_EXIT("%s:%d: JSON parsing error: '%s'\n", __FILE__, __LINE__, err.c_str());
  if (!config.is<picojson::object>()) EINSTEIN_EXIT("%s:%d: Config is not a JSON object\n", __FILE__, __LINE__);

  // Process config
  //EINSTEIN_LOG("%s:%d: Processing config: '%s'...\n", __FILE__, __LINE__, config.serialize().c_str());
  hook_writes = config.get("options").get("hook_writes").get<bool>();
  do_rewrites = config.get("options").get("do_rewrites").get<bool>();
  memtaint_set_only_do_callback(do_rewrites);
  picojson::array rewrites_config = config.get("rewrites").get<picojson::array>();
  for (size_t i = 0; i < rewrites_config.size(); i++) {
    einstein_rewrite this_rewrite = einstein_rewrite(rewrites_config[i]);
    rewrites_list.push_back(this_rewrite);
  }

  // For debugging...
  //for (size_t i = 0; i < rewrites_list.size(); i++) EINSTEIN_LOG("%s:%d: rewrites_list[%lu]: '%s'\n", __FILE__, __LINE__, i, rewrites_list[i].to_str().c_str());
  //EINSTEIN_EXIT("%s:%d: Done! Exiting...\n", __FILE__, __LINE__);

  //EINSTEIN_LOG("%s:%d: Done processing config.\n", __FILE__, __LINE__);
  return;
}
