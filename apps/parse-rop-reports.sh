#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <dir>"
  echo "E.g.: '$0 nginx-1.23.0' to parse _only nginx_ reports"
  echo "Or:   '$0 ALL' to parse _all_ reports"
  exit 1
fi

if [ "$1" = "ALL" ]; then
  APP="*"
else
  APP=$1
fi

grep -Irsh "Found indirect control flow: " ./${APP}/.tmp/* | grep -v 'backtrace\": \[[^]]*cmdsvr' | sort | uniq | sed 's/Found indirect control flow: //' | sed '1s/^/[/;$!s/$/,/;$s/$/]/'
