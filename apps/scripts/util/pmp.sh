#!/bin/bash

trap pmp_int INT
trap pmp_int USR1

function pmp_output()
{
    cat $OUT_FILE | \
    awk '
      BEGIN { s = ""; }
      /^Thread/ { print s; s = ""; }
      /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } }
      END { print s }' | \
    sort | grep -v "^$" | uniq -c | sort -r -n -k 1,1
    rm -f $OUT_FILE $ERR_FILE
}

function pmp_int()
{
    echo ""
    pmp_output
    exit 0
}

pid=$1
nsamples=10

SLEEP_SECS=${SLEEP_SECS:-0.2}

if [ $# -gt 1 ]; then
    nsamples=$2
    if [ $nsamples -eq 0 ]; then
        nsamples=1000000000
    fi
fi

ERR_FILE=$(mktemp --tmpdir pmp_errXXXXXX)
OUT_FILE=$(mktemp --tmpdir pmp_outXXXXXX)

x=0
while [ $x -lt $nsamples ];
  do
    sudo gdb -ex "set pagination 0" -ex "thread apply all bt" -batch -p $pid 1>> $OUT_FILE 2> $ERR_FILE
    if grep -q "No such process" $ERR_FILE; then
        break
    fi
    sleep $SLEEP_SECS
    let x=x+1
  done

pmp_output

