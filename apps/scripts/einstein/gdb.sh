#!/bin/bash

MYPWD=`pwd`
ROOT=${ROOT:-../..}

. $ROOT/apps/scripts/include/build.inst.inc

GDB_PIN_SCRIPT=$(dirname $0)/../pin/gdb.sh
PIN_APP_LD_PRELOAD=$INSTALL_DIR/libdbt-cmdsvr.so PIN_INJECTION_DYNAMIC=1 GDB_PIN=einstein.pin $GDB_PIN_SCRIPT $*
