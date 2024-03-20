#!/bin/bash

set -o errexit
set -o errtrace

function cmdctl_client_panalysis {
    file_list=""
    for pid in $(./serverctl pids); do
        # Signification of stctl flags used:
        # - (-x) No timeout
        # - (-L) Likely pointer analysis
        # - (-u) Scan unions
        # - (-I) Scan integers
        # - (-O) Dump source object info
        eval $SUDO_PREFIX ../../bin/stctl -x -L -u -I -O ping $pid
        file_list="$file_list $LOGDIR/analysis.txt.$pid"
    done
    eval $SUDO_PREFIX python ../scripts/st/panalysis_aggregate.py likely $file_list > $LOGDIR/analysis.txt
    eval $SUDO_PREFIX mv $LOGDIR/analysis.txt p_likely_analysis.txt
    file_list=""
    for pid in $(./serverctl pids); do
        # Signification of stctl flags used:
        # - (-x) No timeout
        # - (-R) Real (precise) pointer analysis
        # - (-u) Scan unions
        # - (-I) Scan integers
        # - (-O) Dump source object info
        eval $SUDO_PREFIX ../../bin/stctl -x -R -u -I -O ping $pid
        file_list="$file_list $LOGDIR/analysis.txt.$pid"
    done
    eval $SUDO_PREFIX python ../scripts/st/panalysis_aggregate.py real $file_list > $LOGDIR/analysis.txt
    eval $SUDO_PREFIX mv $LOGDIR/analysis.txt p_real_analysis.txt

    $SUDO_PREFIX rm $LOGDIR/analysis.*
}


