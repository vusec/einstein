#include "einstein_common.h"
#include "einstein_dftrop.h"
#include "einstein_callback.h"
#include "einstein_utils.h"
#include "einstein_debug.h"
#include "einstein_rewrite.h"

// =====================================================================
// Global variables
// =====================================================================

PinLog *_einstein_log;
bool _einstein_use_log = false;

// =====================================================================
// Command line switches
// =====================================================================

static KNOB<string> KnobLogPath(KNOB_MODE_WRITEONCE, "pintool", "logdir", "", "Log directory");
static KNOB<string> KnobLogAppName(KNOB_MODE_WRITEONCE, "pintool", "appname", "", "Name of target application");
static KNOB<string> KnobConfigPath(KNOB_MODE_WRITEONCE, "pintool", "config", "", "Config file to override default vars");

// =====================================================================
// Main
// =====================================================================

int main(int argc, char *argv[]) {
    // PIN initialization boilerplate
    PIN_InitSymbols();
    if (PIN_Init(argc, argv)) {
      std::cerr << "Error in PIN_Init." << std::endl;
      goto err0;
    }

    // Parse command line options
    // -- KnobLogAppName
    if (KnobLogAppName.Value().empty()) {
      std::cerr << "Error: Option '-appname' not supplied" << std::endl;
      std::cerr << KNOB_BASE::StringKnobSummary();
      goto err0;
    }
    application_name = KnobLogAppName.Value();
    // -- KnobConfigPath
    if (!KnobConfigPath.Value().empty()) einstein_config_parse(KnobConfigPath.Value());
    //EINSTEIN_LOG("Running with hook_writes=%s...\n", hook_writes ? "true" : "false");

    // Set memtaint options
    memtaint_enable_snapshot(KnobLogPath.Value().empty() ? string(ROOT) + "/results/misc/default-cores/" + application_name + ".core" : KnobLogPath.Value() + "core");
    memtaint_set_callback(einstein_rewrite_init);
    memtaint_dont_taint_nonwritable_mem();
    memtaint_dont_taint_stack_mem();
    tag_trait_set_print_decimal(true);

    // Add instrumentation functions
#ifdef DFTROP
    instrumentations_dftrop();
#endif
    //einstein_debug_exceptions();
    //einstein_debug_instructions();

    // Parse (more) command line options
    // This needs to go after instrumentations_dftrop() because this calls PIN_AddThreadFiniFunction() with a callback that uses EINSTEIN_LOG()
    // -- KnobLogPath
    if (!KnobLogPath.Value().empty()) {
      // Set log directory for libdft and Einstein
      libdft_set_log_dir(KnobLogPath.Value(), true);
      _einstein_log = new PinLogPerThread((KnobLogPath.Value() + "/einstein.%s.out").c_str());
      _einstein_use_log = true;
    }

    // Initialize libdft with load ptr prop enabled
    if (libdft_init() != 0) {
      std::cerr << "Error libdft_init." << std::endl;
      goto err1;
    }

    // Add callbacks
#ifdef DFTROP
    callbacks_dftrop();
#else
    callbacks_einstein();
#endif

    // Start the program, never returns
    PIN_StartProgram();
    return EXIT_SUCCESS; // Not reached, but makes the compiler happy

err1:
    libdft_die(); // Detach from the process

err0:
    return EXIT_FAILURE;
}
