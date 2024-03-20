#!/bin/bash

MYPWD=`pwd`
ROOT=${ROOT:-../..}

TOOL_NAME="$GDB_PIN"
APP="$@"
APP_AND_ITS_ARGS="$*"

. $ROOT/apps/scripts/include/build.inst.inc

# Dynamic injection mode of PIN is prevented by Linux. For more info:
#  https://software.intel.com/sites/landingpage/pintool/docs/71313/Pin/html/index.html#INJECTION

if [ -z "$PIN_INJECTION_DYNAMIC" ]; then
  echo "  [PIN-GDB] Injection mode = child "
  echo "  [PIN-GDB] For default mode (dynamic) first do:"
  echo "  [PIN-GDB]   \$ sudo bash -c \"echo 0 > /proc/sys/kernel/yama/ptrace_scope\""
  echo "  [PIN-GDB] then start PIN instrumentation with env var: PIN_INJECTION_DYNAMIC=1"
  PIN_OPS="-injection child ${PIN_OPS}"
else
  echo "  [PIN-GDB] Injection mode = dynamic (default)"
fi

# set up file names that will contain the output of the PIN instrumentation
PIN_GDB_OUT="${TOOL_NAME}.gdb.out"
PIN_GDB_ERR_OUT="${TOOL_NAME}.gdb.err.out"

echo "  [PIN-GDB] Output and error output are respectively logged in: "
echo "  [PIN-GDB]   ${PIN_GDB_OUT}  &  ${PIN_GDB_ERR_OUT}"

# start the PIN instrumentation in the background
$PIN_ROOT/pin -appdebug $PIN_OPS -t $INSTALL_DIR/$TOOL_NAME $PIN_TOOL_OPS -- $APP_AND_ITS_ARGS > $PIN_GDB_OUT 2> $PIN_GDB_ERR_OUT &

# Retrieve the process ID of the PIN instrumentation process
sleep 0.5 # wait a little for PIN to print the gdb command and process ID to file
PIN_PROCESS_ID=$( grep target ${PIN_GDB_OUT} | awk -F: '{print $2}' )
echo "  [PIN-GDB] Attaching GDB to TCP port: ${PIN_PROCESS_ID}"

# Start GDB and attach to the PIN instrumentation process
echo -e "target remote :${PIN_PROCESS_ID} " > _gdb_cmds
gdb --command=_gdb_cmds --args $APP_AND_ITS_ARGS
rm -f _gdb_cmds

###############################################
#GDB_PIN=<tool_name> (PIN_INJECTION_DYNAMIC=1) (PIN_OPS=<pin-ops>) (PIN_TOOL_OPS=<pin-tool-ops>) ./serverctl start <app-args>

# More info on the PIN and PIN_TOOL options: 
# https://software.intel.com/sites/landingpage/pintool/docs/71313/Pin/html/group__KNOBS.html
