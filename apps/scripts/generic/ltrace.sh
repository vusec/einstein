#!/bin/bash

PID=${PID:-}
LTRACE_OPTS=${LTRACE_OPTS:-"-f -tt -o $(pwd)/.tmp/ltrace"}

if [ "$PID" != "" ]; then
	sudo ltrace -p $PID ${LTRACE_OPTS}.$PID &
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

eval $PRE_ARGS ltrace ${LTRACE_OPTS}.out $ARGS &

