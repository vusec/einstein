#!/bin/bash

PID=${PID:-}
STRACE_OPTS=${STRACE_OPTS:-"-o $(pwd)/.tmp/strace -ff -tt"}

if [ "$PID" != "" ]; then
	sudo strace -p $PID $STRACE_OPTS &
	exit 0
fi

ARGS=""
PRE_ARGS=""
BIN_FOUND=0
BIN_PATH=$( ./clientctl bin )
for a in "$@"
do
	if echo $a | grep -q $BIN_PATH; then
		BIN_FOUND=1
	fi
	if [ $BIN_FOUND -eq 0 ]; then
		PRE_ARGS+=" $a"
	else
		ARGS+=" $a"
	fi
done

eval $PRE_ARGS strace $STRACE_OPTS $ARGS &
