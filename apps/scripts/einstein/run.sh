#!/bin/bash

MYPWD=`pwd`
ROOT=${ROOT:-../..}

. $ROOT/apps/scripts/include/build.inst.inc

PIN_TOOL_OPS="${PIN_TOOL_OPS} -appname ${PROC_NAME}"

if [ -n "$LOG_SUB_DIR" ]; then
  LOGDIR=${LOGDIR}/${LOG_SUB_DIR}/
  mkdir -p ${LOGDIR}
fi

if [ -n "$USE_LOG_DIR" ]; then
  PIN_TOOL_OPS="${PIN_TOOL_OPS} -logdir ${LOGDIR}"
fi

if [ -z "$NO_EINSTEIN_CONFIG" ]; then
  PIN_TOOL_OPS="${PIN_TOOL_OPS} -config ${INSTALL_DIR}/einstein-config.json"
fi

# No ASLR by default (because by default, 'ASLR' will not be defined)
if [ -z "$ASLR" ]; then
  PRE_PIN_CMD="setarch x86_64 -R"
fi

PIN_FOLLOW_EXECV=${PIN_FOLLOW_EXECV:-0}

RUN_PIN_SCRIPT=$(dirname $0)/../pin/run.sh
PIN_APP_LD_PRELOAD=$INSTALL_DIR/libdbt-cmdsvr.so RUN_PIN=einstein.pin PIN_FOLLOW_EXECV=${PIN_FOLLOW_EXECV} PIN_INJECTION_DYNAMIC=1 PIN_TOOL_OPS=${PIN_TOOL_OPS} PRE_PIN_CMD=${PRE_PIN_CMD} $RUN_PIN_SCRIPT $*

