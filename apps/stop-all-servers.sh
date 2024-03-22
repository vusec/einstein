#!/bin/bash

set +e

echo "Stopping all servers..."

# Run './serverctl stop' for all apps
find ./*/serverctl | grep -v "^\./tests\/" | sed 's/\/serverctl.*//' | xargs -I{} sh -c "cd {} && ./serverctl stop" > /dev/null

# Kill scripts
pkill clientctl
pkill runbench
pkill serverctl

# Kill processes using port 1080, just to be safe
KILL_PID=$(sudo lsof -t -i:1080)
[[ ! -z ${KILL_PID} ]] && kill ${KILL_PID}

exit 0
