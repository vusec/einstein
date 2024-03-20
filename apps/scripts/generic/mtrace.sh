#!/bin/bash

PID=${PID:-}
MTRACE_FILE=${MTRACE_FILE:-"$(pwd)/.tmp/mtrace"}

if [ "$PID" != "" ]; then
	./serverctl gdb $PID "call putenv(\"MALLOC_TRACE=${MTRACE_FILE}.${PID}\")\ncall mtrace()" &> /dev/null
	exit 0
fi

ARGS="$@"

(
	./serverctl wait pid
	./serverctl gdb pid "call putenv(\"MALLOC_TRACE=${MTRACE_FILE}.out\")\ncall mtrace()\nset gdbinit_done=1" &> /dev/null
) &
if echo $ARGS | grep -q "scripts.*\.sh"; then
	LD_PRELOAD_OPTS=LD_PRELOAD_=$LD_PRELOAD_:../../bin/libgdbinit.so
else
	LD_PRELOAD_OPTS=LD_PRELOAD=$LD_PRELOAD:../../bin/libgdbinit.so
fi
eval $LD_PRELOAD_OPTS $ARGS

