#ifndef EINSTEIN_REWRITE_H
#define EINSTEIN_REWRITE_H

extern bool do_rewrites;

bool einstein_rewrite_check_buf(void * target_ptr, size_t target_len, const void * canary_data, size_t canary_len);
bool einstein_rewrite_check_ppchar(char ** pptr, const void * canary_data, size_t canary_len);
bool einstein_rewrite_check_iovec(struct iovec *target_iov, size_t target_iovcnt, const void * canary_data, size_t canary_len);
static inline bool einstein_rewrite_check_int(void * target_ptr, int canary) { return einstein_rewrite_check_buf(target_ptr, sizeof(int), &canary, sizeof(int)); }
static inline bool einstein_rewrite_check_sizet(void * target_ptr, size_t canary) { return einstein_rewrite_check_buf(target_ptr, sizeof(size_t), &canary, sizeof(size_t)); }
static inline bool einstein_rewrite_check_vptr(void * target_ptr, void * canary) { return einstein_rewrite_check_buf(target_ptr, sizeof(void*), &canary, sizeof(void*)); }
static inline bool einstein_rewrite_check_offt(void * target_ptr, off_t canary) { return einstein_rewrite_check_buf(target_ptr, sizeof(off_t), &canary, sizeof(off_t)); }
static inline bool einstein_rewrite_check_socklent(void * target_ptr, socklen_t canary) { return einstein_rewrite_check_buf(target_ptr, sizeof(off_t), &canary, sizeof(socklen_t)); }
void einstein_rewrite_check(syscall_ctx_t * ctx);

void einstein_rewrite_init_buf(string type, size_t ptr_depth, void * target_address, size_t target_len, const void * canary_data, size_t canary_len);
static inline void einstein_rewrite_init_int(string type, size_t ptr_depth, void * target_address, size_t target_len, int canary) { einstein_rewrite_init_buf(type, ptr_depth, target_address, target_len, &canary, sizeof(int)); }
static inline void einstein_rewrite_init_sizet(string type, size_t ptr_depth, void * target_address, size_t target_len, size_t canary) { einstein_rewrite_init_buf(type, ptr_depth, target_address, target_len, &canary, sizeof(int)); }
static inline void einstein_rewrite_init_vptr(string type, size_t ptr_depth, void * target_address, size_t target_len, void * canary) { einstein_rewrite_init_buf(type, ptr_depth, target_address, target_len, &canary, sizeof(void*)); }
static inline void einstein_rewrite_init_offt(string type, size_t ptr_depth, void * target_address, size_t target_len, off_t canary) { einstein_rewrite_init_buf(type, ptr_depth, target_address, target_len, &canary, sizeof(off_t)); }
static inline void einstein_rewrite_init_socklent(string type, size_t ptr_depth, void * target_address, size_t target_len, socklen_t canary) { einstein_rewrite_init_buf(type, ptr_depth, target_address, target_len, &canary, sizeof(socklen_t)); }
void einstein_rewrite_init(void);

void einstein_config_parse(string path);

#endif
