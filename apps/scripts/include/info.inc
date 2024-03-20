#!/bin/bash

set -o errexit
set -o errtrace

function info_exit_usage {
    echo "Usage: info [sig|fd|maps|smaps|bt|stacksize|pmp|mem|mem-h|mem-ht] [action]"
    echo " - Available actions: "
    echo "     <pid>"
    echo "     [$0 pid action]"

    exit 1
}

function info_sig_run {
    $SUDO_PREFIX ../scripts/util/checksignals.pl $*
}

function info_fd_run {
    $SUDO_PREFIX lsof -a -p $*
}

function info_maps_run {
    $SUDO_PREFIX cat /proc/$*/maps
}

function info_smaps_run {
    $SUDO_PREFIX cat /proc/$*/smaps
}

function info_bt_run {
    $SUDO_PREFIX gdb -ex "set pagination 0" -ex "thread apply all bt" --batch -p $*
}

function info_stacksize_run {
    $SUDO_PREFIX gdb -ex 'p $rsp' -ex 'up 99999' -ex 'p (char*) &argc - (char*) $1' --batch -p $* 2>&1 | awk '$1 ~ /\$2/ { print $3 }'
}

function info_pmp_run {
    $SUDO_PREFIX ../scripts/util/pmp.sh $*
}

function info_mem_run {
    #ps -o vsz,rss -p $* | tail -n +2
    $SUDO_PREFIX cat /proc/$1/smaps | awk '$1 ~ /Size:/ { VSZ+=$2 } $1 ~ /Rss:/ { RSS+=$2 } $1 ~ /Pss:/ { PSS+=$2 } END{ print VSZ,RSS,PSS }'
}

function info_memh_run {
    PIDS=$(  info_proc_hierarchy_ps $1 1 pid )
    for pid in $PIDS
    do
        info_mem_run $pid
    done
}

function info_memht_run {
    info_memh_run $1 | awk '{ NUM++; VSZ += $1; RSS += $2; PSS += $3; } END { print NUM,VSZ,RSS,PSS }'
}

function info_proc_hierarchy_ps {
    local child_columns=$(( 3 + $2 ))
    ps --forest -e -o ${3},pid,comm | awk "{ if ( \$( $2 + 1 ) ~ /^$1\$/ ) { do_print=1 } else if ( NF != $child_columns ) { do_print=0 }; if ( do_print == 1 ) { end=$2; printf(\$1); for(i=2;i<=end;i++){printf(\" %s\",\$i)}; printf(\"\n\") } }"
}

function info_run {
    echo " ***** Running: $*"
    eval $*
    echo ""
}

function info_action {
    local cmd=$1
    local mode=$2

    SUDO_PREFIX=sudo
    case "$cmd" in
      'sig')
          cmd=info_sig_run
        ;;
      'fd')
          cmd=info_fd_run
        ;;
      'maps')
          cmd=info_maps_run
        ;;
      'smaps')
          cmd=info_smaps_run
        ;;
      'bt')
          cmd=info_bt_run
        ;;
      'stacksize')
          cmd=info_stacksize_run
        ;;
      'pmp')
          cmd=info_pmp_run
        ;;
      'mem')
          cmd=info_mem_run
        ;;
      'mem-h')
          cmd=info_memh_run
        ;;
      'mem-ht')
          cmd=info_memht_run
        ;;
      *)
        info_exit_usage
        ;;
    esac

    shift || true
    shift || true
    case "$mode" in
      '')
        info_exit_usage
        ;;
      *)
        for pid in $( eval $0 $mode )
        do
            info_run $cmd $pid $*
        done
        ;;
    esac
}

