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

grep -Irsh "Found syscall: " ./${APP}/.tmp/* | sort | uniq | sed 's/Found syscall: //' | sed '1s/^/[/;$!s/$/,/;$s/$/]/'

