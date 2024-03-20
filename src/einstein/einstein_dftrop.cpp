#include "einstein_common.h"
#include "einstein_utils.h"

#define WITH_SYMS false

string details_qword(ADDRINT val, tagqarr_t val_taint);

// =====================================================================
// Utilities
// =====================================================================

class thread_data_t {
  public:
    std::unordered_map<string, string> reports;
};
static TLS_KEY tls_key = INVALID_TLS_KEY;

static void set_tdata(thread_data_t* tdata, THREADID tid) { if (PIN_SetThreadData(tls_key, tdata, tid) == FALSE) EINSTEIN_EXIT("Error: PIN_SetThreadData failed\n"); }
static thread_data_t* get_tdata(THREADID tid) { return static_cast<thread_data_t*>(PIN_GetThreadData(tls_key,tid)); }

static string dftreport_key(string bt, string target_details) { return bt + "-" + target_details; }

static bool dftreport_exists(THREADID tid, string key) {
    thread_data_t* tdata = get_tdata(tid);
    return tdata->reports.find(key) != tdata->reports.end();
}
static void dftreport_add(THREADID tid, string key, string report) {
    thread_data_t* tdata = get_tdata(tid);
    tdata->reports[key] = report;
}

// ================

static void dftrop_report_log(thread_data_t* tdata) {
    string reports_s = "";
    for (auto it = tdata->reports.begin(); it != tdata->reports.end(); it++) { reports_s += it->second; }
    EINSTEIN_LOG("%s", reports_s.c_str());
}

static void dftrop_report(string operand_type, bool is_tainted, CONTEXT *ctx, string target_details, THREADID tid, ADDRINT rip) {
    string bt = bt_str(ctx, WITH_SYMS, false);
    string key = dftreport_key(bt, target_details);
    if (dftreport_exists(tid, key)) return;
    string report = "Found indirect control flow: {"
            "\"operand_type\": \"" + operand_type + "\", "
            "\"pid\": " + my_to_string(PIN_GetPid()) + ", \"ppid\": " + my_to_string(getppid()) + ", \"tid\": " + my_to_string(PIN_GetTid()) + ", \"ptid\": " + my_to_string(PIN_GetParentTid()) + ", "
            "\"tainted\": " + (is_tainted ? "true" : "false") + ", "
            "\"application\": \"" + str_replace(application_name, "\"", "\\\"") + "\", "
            "\"application_testcase\": \"" + str_replace(string(_libdft_debug_str), "\"", "\\\"") + "\", "
            "\"application_corepath\": \"" + str_replace(memtaint_get_snapshot_path(), "\"", "\\\"") + "\", "
            "\"application_corenum\": " + my_to_string(memtaint_get_snapshot_num()) + ", "
            "\"backtrace\": " + bt + ", "
            "\"rip\": " + my_to_string(rip) + ", "
            "\"target\": " + target_details + "}\n";
    dftreport_add(tid, key, report);
}

// ================

VOID dftrop_threadstart(THREADID tid, CONTEXT* ctxt, INT32 flags, VOID* v) {
    thread_data_t* tdata = new thread_data_t;
    set_tdata(tdata, tid);
}

VOID dftrop_threadfini(THREADID tid, const CONTEXT* ctxt, INT32 code, VOID* v) {
    thread_data_t* tdata = get_tdata(tid);
    dftrop_report_log(tdata);
    delete tdata;
}

// =====================================================================
// Analysis routines
// =====================================================================

static void process_call_reg(CONTEXT *ctx, THREADID tid, ADDRINT rsp, ADDRINT rip, ADDRINT btarget, UINT32 base_reg_u) {
    REG base_reg=(REG)base_reg_u;

    // Get the tag of the base
    int libdft_base_reg = REG_INDX(base_reg);
    if (libdft_base_reg == GRP_NUM) {
        EINSTEIN_LOG("==== %s:%d: PIN to libdft reg indx conversion not supported for reg %u\n", __FILE__, __LINE__, base_reg);
        return;
    }
    tagqarr_t tagq = tagmap_getqarr_reg(tid, libdft_base_reg, sizeof(ADDRINT));
    bool is_tainted = !tagqarr_is_empty(tagq);

    if (!is_tainted) return; // If reg is untainted, skip

    string target_sym = WITH_SYMS ? cptr_to_symbol((void*)btarget) : "NO_SYMS";

    string target_details = "{\"reg\": " + details_qword(PIN_GetContextReg(ctx, base_reg), tagq) + ", "
                             "\"target_ip\": " + my_to_string(btarget) + ", "
                             "\"target_sym\": \"" + target_sym + "\"}";
    dftrop_report("register", is_tainted, ctx, target_details, tid, rip);
}

static void process_call_mem(CONTEXT *ctx, THREADID tid, ADDRINT rsp, ADDRINT rip, ADDRINT btarget, UINT32 base_reg_u, UINT32 indx_reg_u, ADDRINT read_ea) {
    tagqarr_t base_tagq, indx_tagq, cptr_tagq;
    REG base_reg=(REG)base_reg_u, indx_reg=(REG)indx_reg_u;

    // Get the tag of the base
    int libdft_base_reg = REG_INDX(base_reg);
    if (base_reg == REG_RIP) {
        // It's okay if the base_reg is RIP (this is very common)
        base_tagq = tagqarr_t();
    }
    else if (libdft_base_reg == GRP_NUM) {
        EINSTEIN_LOG("==== %s:%d: PIN to libdft reg indx conversion not supported for reg %u\n", __FILE__, __LINE__, base_reg);
        return;
    }
    else {
        // The base_reg is a normal GPR
        base_tagq = tagmap_getqarr_reg(tid, libdft_base_reg, sizeof(ADDRINT));
    }

    // Get the tag of the index
    int libdft_indx_reg = REG_INDX(indx_reg);
    if (indx_reg == REG_INVALID()) {
        // It's okay if the indx_reg is invalid (this is very common, because it may be an immediate)
        indx_tagq = tagqarr_t();
    }
    else if (libdft_indx_reg == GRP_NUM) {
        EINSTEIN_LOG("==== %s:%d: PIN to libdft reg indx conversion not supported for reg %u\n", __FILE__, __LINE__, indx_reg);
        return;
    }
    else {
        // The indx_reg is a normal GPR
        indx_tagq = tagmap_getqarr_reg(tid, libdft_indx_reg, sizeof(ADDRINT));
    }

    // Get the tag of the code pointer
    cptr_tagq = tagmap_getqarr(read_ea);

    // This is tainted if: base is tainted, OR index is tainted, OR cptr is tainted
    bool is_tainted = !tagqarr_is_empty(base_tagq) || !tagqarr_is_empty(indx_tagq) || !tagqarr_is_empty(cptr_tagq);

    if (!is_tainted) return; // If reg is untainted, skip

    string target_sym = WITH_SYMS ? cptr_to_symbol((void*)btarget) : "NO_SYMS";

    string target_details = "{\"base\": " + details_qword(PIN_GetContextReg(ctx, base_reg), base_tagq) + ", "
                            "\"indx\": " + details_qword(PIN_GetContextReg(ctx, indx_reg), indx_tagq) + ", "
                            "\"cptr\": " + details_qword(btarget, cptr_tagq) + ", "
                            "\"target_ip\": " + my_to_string(btarget) + ", "
                            "\"target_sym\": \"" + target_sym + "\"}";
    dftrop_report("memory", is_tainted, ctx, target_details, tid, rip);
}

// =====================================================================
// Instrumentation callbacks
// =====================================================================

static VOID instrument_indirect(TRACE trace, VOID *v) {
    for (BBL bbl = TRACE_BblHead(trace); BBL_Valid(bbl); bbl = BBL_Next(bbl)) {
        INS tail = BBL_InsTail(bbl);

        if(INS_IsIndirectControlFlow(tail)) {
            REG base_reg = REG_INVALID();
            REG indx_reg = REG_INVALID();

            // Indirect target is a register operand
            if (INS_OperandIsReg(tail, 0)) {
                //EINSTEIN_LOG("Instrumenting indirect branch/call with REGISTER target: rip = %p, disas = '%s'\n", INS_Address(tail), INS_Disassemble(tail).c_str());
                base_reg = INS_OperandReg(tail, 0);
                INS_InsertCall(tail,
                    IPOINT_BEFORE,
                    (AFUNPTR)process_call_reg,
                    IARG_CONTEXT,
                    IARG_THREAD_ID,
                    IARG_REG_VALUE, LEVEL_BASE::REG_RSP,
                    IARG_INST_PTR,
                    IARG_BRANCH_TARGET_ADDR,
                    IARG_UINT32, base_reg,
                    IARG_END);
            }
            // Indirect target is a memory operand
            else if (INS_OperandIsMemory(tail, 0)) {
                //EINSTEIN_LOG("Instrumenting indirect branch/call with MEMORY target:   rip = %p, disas = '%s'\n", INS_Address(tail), INS_Disassemble(tail).c_str());
                base_reg = INS_OperandMemoryBaseReg(tail, 0);
                indx_reg = INS_OperandMemoryIndexReg(tail, 0);
                INS_InsertCall(tail,
                    IPOINT_BEFORE,
                    (AFUNPTR)process_call_mem,
                    IARG_CONTEXT,
                    IARG_THREAD_ID,
                    IARG_REG_VALUE, LEVEL_BASE::REG_RSP,
                    IARG_INST_PTR,
                    IARG_BRANCH_TARGET_ADDR,
                    IARG_UINT32, base_reg,
                    IARG_UINT32, indx_reg,
                    IARG_MEMORYREAD_EA,
                    IARG_END);
            }
        }
    }
}

// =====================================================================
// Janky callback to fix issue when the LD_PRELOADed cmdsvr is forwarded to execve
// =====================================================================

void dftrop_execve_hook(THREADID tid, syscall_ctx_t *ctx) {
  void fix_syscall_args(syscall_ctx_t *ctx);
  fix_syscall_args(ctx);
}

// =====================================================================
// Interfaces
// =====================================================================

VOID instrumentations_dftrop(VOID) {
    TRACE_AddInstrumentFunction(instrument_indirect, 0);

    tls_key = PIN_CreateThreadDataKey(NULL);
    if (tls_key == INVALID_TLS_KEY) EINSTEIN_EXIT("Error: Number of already allocated keys reached the MAX_CLIENT_TLS_KEYS limit\n");
    PIN_AddThreadStartFunction(dftrop_threadstart, NULL);
    PIN_AddThreadFiniFunction(dftrop_threadfini, NULL);
}

VOID callbacks_dftrop(VOID) {
    syscall_set_pre(&syscall_desc[__NR_execve], dftrop_execve_hook);
    syscall_set_pre(&syscall_desc[__NR_execveat], dftrop_execve_hook);
}
