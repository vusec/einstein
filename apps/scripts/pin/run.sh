#!/bin/bash

MYPWD=`pwd`
ROOT=${ROOT:-../..}

TOOL_NAME=$RUN_PIN

. $ROOT/apps/scripts/include/build.inst.inc

PIN_FOLLOW_EXECV=${PIN_FOLLOW_EXECV:-1}

[ $PIN_FOLLOW_EXECV -eq 1 ] && PIN_OPS="$PIN_OPS -follow_execv"

if [ -z "$PIN_INJECTION_DYNAMIC" ]; then
  echo "  [PIN] Injection mode: child"
  PIN_OPS="-injection child ${PIN_OPS}"
else
  echo "  [PIN] Injection mode: dynamic (default)"
fi

PIN_OPS=$(echo "$PIN_OPS" | xargs) # strip excess whitespace :P
echo   "  [PIN]    Pin options: ${PIN_OPS}"

# Echo commands after this point when V is set.
[ "$V" != "" ] && set -x

$PRE_PIN_CMD $PIN_ROOT/pin $PIN_OPS -t $INSTALL_DIR/$TOOL_NAME $PIN_TOOL_OPS -- $*

#RUN_PIN=<tool_name>.pin (PIN_INJECTION_DYNAMIC=1) (PIN_OPS=<pin-ops>) (PIN_TOOL_OPS=<pin-tool-ops>) ./serverctl start <nginx-binary-args>

# More info on the PIN and PIN_TOOL options: 
# https://software.intel.com/sites/landingpage/pintool/docs/71313/Pin/html/group__KNOBS.html
