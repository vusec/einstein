#!/bin/bash

VGRIND_OPTS=${VGRIND_OPTS:-"--trace-children=yes --track-fds=yes --time-stamp=yes --read-var-info=yes --leak-check=full --log-file=$(pwd)/.tmp/valgrind.out"}

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

eval $PRE_ARGS valgrind $VGRIND_OPTS $ARGS &

