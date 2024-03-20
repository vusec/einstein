#!/bin/sh

set -e

find ./*/serverctl | grep -v "^\./tests\/" | sed 's/\/serverctl.*//' | xargs -I{} sh -c "cd {} && ./serverctl stop" > /dev/null

