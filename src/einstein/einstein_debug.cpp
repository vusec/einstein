#include "einstein_common.h"
#include "einstein_utils.h"

static bool hit_exception = false;

// =====================================================================
// Debugging exceptions
// =====================================================================

// From Pin's source code at source/tools/ManualExamples/stack-debugger.cpp
static void ConnectDebugger() {
    if (PIN_GetDebugStatus() != DEBUG_STATUS_UNCONNECTED) {
        EINSTEIN_LOG("%s:%d: Not connecting because already connected\n", __FILE__, __LINE__);
        return;
    }

    DEBUG_CONNECTION_INFO info;
    if (!PIN_GetDebugConnectionInfo(&info) || info._type != DEBUG_CONNECTION_TYPE_TCP_SERVER) {
        EINSTEIN_LOG("%s:%d: Not connecting because no debug connection\n", __FILE__, __LINE__);
        return;
    }

    EINSTEIN_LOG("%s:%d: Triggered stack-limit breakpoint.\n", __FILE__, __LINE__);
    EINSTEIN_LOG("%s:%d: Start GDB and enter this command:\n", __FILE__, __LINE__);
    EINSTEIN_LOG("%s:%d:   target remote :%d\n", __FILE__, __LINE__, info._tcpServer._tcpPort);

    if (PIN_WaitForDebuggerToConnect(1000*20))
        return;

    EINSTEIN_LOG("%s:%d: No debugger attached after 20 seconds.\n", __FILE__, __LINE__);
    EINSTEIN_LOG("%s:%d: Resuming application without stopping.\n", __FILE__, __LINE__);
}

static EXCEPT_HANDLING_RESULT ExceptionHandler(THREADID threadIndex, EXCEPTION_INFO * pExceptInfo,
                                      PHYSICAL_CONTEXT * pPhysCtxt, VOID *v) {
    hit_exception = true;
    EINSTEIN_LOG("%s:%d: *** Exception info start ***\n", __FILE__, __LINE__);
    EINSTEIN_LOG("%s:%d: ExceptionHandler: Caught unexpected exception. %s\n", __FILE__, __LINE__, PIN_ExceptionToString(pExceptInfo).c_str());

    std::string ins_filename; INT32 ins_line, ins_col; PIN_LockClient(); PIN_GetSourceLocation(pExceptInfo->GetExceptAddress(), &ins_col, &ins_line, &ins_filename); PIN_UnlockClient();
    EINSTEIN_LOG("%s:%d: Source location: %s:%d:%d\n", __FILE__, __LINE__, ins_filename.c_str(), ins_line, ins_col);

    EINSTEIN_LOG("%s:%d: Backtrace: %s\n", __FILE__, __LINE__, bt_str(pPhysCtxt->_pCtxt, true, true).c_str());
    EINSTEIN_LOG("%s:%d: Going to connect debugger...\n", __FILE__, __LINE__);
    ConnectDebugger();
    PIN_ApplicationBreakpoint(pPhysCtxt->_pCtxt, threadIndex, FALSE, "Hello!");
    EINSTEIN_LOG("%s:%d: *** Exception info end ***\n", __FILE__, __LINE__);
    return EHR_UNHANDLED;
}

// =====================================================================
// Debugging instructions
// =====================================================================

typedef struct {
  string disassem;
  string src_loc;
} ins_debug_info;

static std::unordered_map<ADDRINT, ins_debug_info> str_of_ins;

static VOID ins_dump(ADDRINT rip, CONTEXT *ctx) {
  if (hit_exception) return;
  EINSTEIN_LOG("rip = %p, ins = '%s', loc = '%s', bt = %s\n",
      (void *)rip,
      str_of_ins[rip].disassem.c_str(),
      str_of_ins[rip].src_loc.c_str(),
      false ? bt_str(ctx, true, true).c_str() : "(skipped)");
}

static VOID add_ins_dump(INS ins, VOID *v) {
  str_of_ins[INS_Address(ins)] = {.disassem = INS_Disassemble(ins), .src_loc = src_loc(INS_Address(ins))};
  INS_InsertCall(ins, IPOINT_BEFORE, (AFUNPTR)ins_dump, IARG_INST_PTR, IARG_CONTEXT, IARG_END);
}

// =====================================================================
// Debugging interfaces
// =====================================================================

void einstein_debug_exceptions() {
    PIN_AddInternalExceptionHandler(ExceptionHandler, NULL);
}

void einstein_debug_instructions() {
    INS_AddInstrumentFunction(add_ins_dump, 0);
}