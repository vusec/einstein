#!/bin/bash

MYPWD=`pwd`
ROOT=${ROOT:-../..}

. $ROOT/apps/scripts/include/configure.inst.inc
. $ROOT/apps/scripts/include/gdb.inc

echo -e "$(gdb_get_init_args)" > _gdb_cmds
gdb --command=_gdb_cmds --args $@
rm -f _gdb_cmds

