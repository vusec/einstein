#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <dir> <serverctl-restart-args>"
  echo "E.g.: $0 lighttpd-1.4.65 -f install/etc/lighttpd.conf"
  exit 1
fi

APP=$1
shift
ARGS=$@

cd ${APP}

echo "Starting ${APP}"
RUN_EINSTEIN=1 USE_LOG_DIR=1 V=1 LOG_SUB_DIR=einstein-simple ./serverctl restart ${ARGS}
sleep 8

echo "Sending 'taintall' command..."
./serverctl udscmd pids dbt taintall
sleep 2

echo "Handling test request"
./clientctl run
sleep 2

echo "Sending 'taintall' command x2..."
./serverctl udscmd pids dbt taintall
sleep 2

echo "Handling test request x2"
./clientctl run
sleep 2

echo "Stopping ${APP}"
RUN_EINSTEIN=1 ./serverctl stop
