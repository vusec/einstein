#ifndef EINSTEIN_UTILS_H
#define EINSTEIN_UTILS_H

#include "einstein_common.h"

// General utilities
string str_to_json_str(string s);
std::string str_replace(std::string str, std::string substr1, std::string substr2);
void concat_str_set(string * curr, string next);
string byte_to_string(uint8_t b, bool in_hex);
string ptr_to_string(const void * ptr, bool in_hex);
bool str_has_ending(std::string const &fullString, std::string const &ending);

// Pin/libdft utilities
bool str_data_is_tainted(const char * ptr);
bool str_arr_data_is_tainted(const char ** str_arr_p);
string str_taint_to_string(const char * ptr);
string path_remove_root(string path);
string bt_str_withlimit(const CONTEXT * ctx, bool with_symbols, bool in_hex, int bt_max_depth);
string bt_str(const CONTEXT * ctx, bool with_symbols, bool in_hex);
bool bt_equals(const CONTEXT * ctx, std::vector<string> exp_bt);
string cptr_to_symbol(void * cptr);
string src_loc(ADDRINT rip);

// Syscall utilities
string fd_info_old(unsigned long fd, tag_t fd_taint);
string str_info(const char * str_p, bool verbose);
string str_arr_info(const char ** str_arr_p, bool verbose);
string char_ptr_info(ADDRINT buf_pa, tag_t buf_p_taint, size_t count);
string prot_info(unsigned long prot);
bool flags_is_writable(int flags);
string flags_to_str(int flags);
unsigned long syscall_name_to_nr(string syscall_name);
#endif