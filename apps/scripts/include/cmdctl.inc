#!/bin/bash

set -o errexit

if [ -z "$ROOT" ]; then
  ROOT=../..
fi

. ${ROOT}/apps/scripts/include/patch.inc
. ${ROOT}/apps/scripts/include/gdb.inc
. ${ROOT}/apps/scripts/include/info.inc
. ${ROOT}/apps/scripts/include/panalysis.inc

function cmdctl_file_to_ini {
    local file=$1
    local section=$2
    local rules=$*
    echo "[$section]"
    for r in $rules
    do
        local pattern=$( echo $r | awk -F :::: '{ print $1 }' )
        local subst=$( echo $r | awk -F :::: '{ print $2 }' | sed "s/=/ = /g" )
        cat $file | sed -n "s/$pattern/$subst/p"
    done
}

function cmdctl_runbench_add_mem_arg {
    local row=$1
    local key=$2
    local column=$3
    awk "\$1 ~ /$row/ { printf(\"$key = %s\n\", \$$column) }" runbench.mem.log | tee -a runbench.log
    RUNBENCH_EXTRA_ARGS+=" ^\($key.*\)$::::\1"
}

function cmdctl_runbench_add_mem_args {
    cmdctl_runbench_add_mem_arg $1 ${2}_vsz 3
    cmdctl_runbench_add_mem_arg $1 ${2}_rss 4
    cmdctl_runbench_add_mem_arg $1 ${2}_pss 5
}

function cmdctl_runbench {
    RUNBENCH_EXTRA_ARGS=""
    local RET=0
    if [ -z $RUNBENCH_CMD_SKIP ]; then
        set -o pipefail
        if [ "$BENCH_MEM" == "1" ]; then
            (
             ./clientctl wait pid
             WATCH=${WATCH:-0} ./clientctl repeat info mem-ht $( ./clientctl pid ) &> runbench.mem.log
            ) &
            BENCH_MEM_PID=$!
        fi
        $(which time) -f "\nrunbench_secs = %e" $RUNBENCH_CMD 2>&1 | tee runbench.log || RET=1
        if [ "$BENCH_MEM" == "1" ]; then
            local kill_pid=$( ./clientctl pid )
            [ "$kill_pid" == "" ] || kill -SIGUSR1 $( ps -eo pid,comm,user,args | grep "$(whoami)" | grep $kill_pid | awk '$2 ~ /repeat.sh/ { print $1 }' )
            wait $BENCH_MEM_PID
            cmdctl_runbench_add_mem_args MAX: runbench_max
            cmdctl_runbench_add_mem_args MEAN: runbench_mean
            cmdctl_runbench_add_mem_args MEDIAN: runbench_median
        fi
    fi
    cmdctl_file_to_ini runbench.log runbench-summary \
        $* \
        "^\(runbench_secs.*\)$::::\1" \
        $RUNBENCH_EXTRA_ARGS > runbench.ini
    return $RET
}

function cmdctl_core_path {
    CORE_PATH=`cat /proc/sys/kernel/core_pattern`
    if [[ "$CORE_PATH" = /* ]]
    then
        echo $CORE_PATH
    else
        echo `dirname $BIN_PATH`/$CORE_PATH
    fi
}

function cmdctl_help_gen {
    cmdctl_server_restart $* 2>&1 | grep -v "Starting" | grep -iv "unknown option"
}

function cmdctl_help_default {
    cmdctl_help_gen -h
}

function cmdctl_help_none {
    echo "$PROC_NAME: No help provided!"
}

function cmdctl_help {
    cmdctl_help_default
}

function cmdctl_disasm {
    objdump -d -g -l $BIN_PATH
}

function cmdctl_disll {
    llvm-dis $BIN_PATH.bc
}

function cmdctl_wait {
    TIMEOUT=${TIMEOUT:-0}
    local counter=1
    local pid_action=$1
    while [ "$( $0 $pid_action )" == "" ]
    do
        if [ $counter -eq $TIMEOUT ]; then
            return 1
        fi
        sleep 0.2
        counter=$(($counter + 1))
    done
    return 0
}

function cmdctl_gen_pid_action {
    local pids=$( ./serverctl $1 )
    shift
    for pid in $pids
    do
        eval $SUDO_PREFIX PID=$pid $*
    done
}

function cmdctl_cmd_action {
    mode=$1
    shift || true
    case $mode in
        'bin')
          echo $BIN_PATH
          ;;
        'bc'|'ll')
          echo "$BIN_PATH.$mode"
          ;;
        'help')
          cmdctl_help || return 1
          ;;
        'core')
          cmdctl_core_path || return 1
          ;;
        'disasm')
          cmdctl_disasm || return 1
          ;;
        'disll')
          cmdctl_disll || return 1
          ;;
        'repeat')
          ${ROOT}/apps/scripts/util/repeat.sh $0 $* || return 1
          ;;
        'wait')
          cmdctl_wait $*
          ;;
        'buildcp')
          ${ROOT}/apps/scripts/cp/build.inst.sh || return 1
          ;;
        'buildqp')
          ${ROOT}/apps/scripts/qprof/build.inst || return 1
          ;;
        'buildub')
          ${ROOT}/apps/scripts/unblockify/build.inst || return 1
          ;;
        'buildst')
          ${ROOT}/apps/scripts/st/build.inst $* || return 1
          ;;
        'buildst_edfi')
          ${ROOT}/apps/scripts/edfi/build.inst magic $* || return 1
          ;;
        'builddiff')
          ${ROOT}/apps/scripts/sbindiffy/build.inst || return 1
          ;;
        'buildinfo')
          ${ROOT}/apps/scripts/info/build.inst || return 1
          ;;
        'buildxl')
          ${ROOT}/apps/scripts/xl/build.inst
          ;;
        'deltafy')
          . ${ROOT}/apps/scripts/delta/build.inst $*
          ;;
        'buildpa')
          ${ROOT}/apps/scripts/pa/build.inst
          ;;
        'patch')
          patch_action $* || return 1
          ;;
        'delta_build_rec')
          . ${ROOT}/apps/scripts/delta/build_record.inst
          ;;
        'gdb')
          gdb_action $* || return 1
          ;;
		'perf')
		  perf_action $*
		  ;;
        'info')
          info_action $* || return 1
          ;;
        'udscmd')
          local pid_action=$1
          shift
          SUDO_PREFIX="" cmdctl_gen_pid_action $pid_action cmdctl_server_udscmd $* || return 1
          ;;
        'strace')
          local pid_action=$1
          shift
          cmdctl_gen_pid_action $pid_action ${ROOT}/apps/scripts/generic/strace.sh $* || return 1
          ;;
        'ltrace')
          local pid_action=$1
          shift
          cmdctl_gen_pid_action $pid_action ${ROOT}/apps/scripts/generic/ltrace.sh $* || return 1
          ;;
        'mtrace')
          local pid_action=$1
          shift
          cmdctl_gen_pid_action $pid_action ${ROOT}/apps/scripts/generic/mtrace.sh $* || return 1
          ;;
        '')
          echo "Missing command action!"
          return 1
          ;;
        *)
          echo "Invalid action: $mode" 1>&2
          return 1
          ;;
    esac
    return 0
}

function cmdctl_server_wait_running {
   TIMEOUT=15 cmdctl_wait pid || true
   if [ "`cmdctl_server_first_pid`" == "" ]; then
       echo "***** Process is gone!"
       exit 1
   fi
}

function cmdctl_server_wait_for_listen_port {
   local DELAY=2
   local TRY_COUNT=30
   local COUNT=0
   local listen_port=$1
   echo "***** Waiting for ${PROC_NAME} server to bind port ${listen_port}..."
   while true; do
       # Check if the process still exists
       cmdctl_server_wait_running || exit 1

       # Check if the server is listening on the right port
       if netstat -tlna | grep -q $listen_port
       then
           break
       fi

       COUNT=$(($COUNT+1))
       if [ $COUNT == $TRY_COUNT ]; then
           exit 1
       fi

       sleep $DELAY
   done
}

function cmdctl_server_wait_for_file {
   local DELAY=2
   local TRY_COUNT=30
   local COUNT=0
   local file=$1
   echo "***** Waiting for ${PROC_NAME} server to create file ${file}..."
   while true; do
       # Check if the process still exists
       cmdctl_server_wait_running || exit 1

       # Check if the file exists
       if [ -e $file ]; then
           break
       fi

       COUNT=$(($COUNT+1))
       if [ $COUNT == $TRY_COUNT ]; then
           exit 1
       fi

       sleep $DELAY
   done
}

function cmdctl_server_check_running {
   if [ "`cmdctl_server_first_pid`" = "" ]; then
       echo "***** No ${PROC_NAME} server running..."
       return 1
   fi
   return 0
}

function cmdctl_server_check_not_running {
   if [ "`cmdctl_server_first_pid`" != "" ]; then
       local server_pids=`cmdctl_server_pids | xargs`
       echo "***** ${PROC_NAME} server already running (pid(s): $server_pids)..."
       return 1
   fi
   return 0
}

function cmdctl_server_killall {
   local server_pids=`cmdctl_server_pids | xargs`
   local signal=$1
   echo "***** Sending signal $signal to ${PROC_NAME} server (pid(s): $server_pids)..."
   for pid in $server_pids
   do
       eval $SUDO_PREFIX kill $signal $pid
   done
}

function cmdctl_server_start {
    echo "***** Starting ${PROC_NAME} server..."
    cmdctl_server_check_not_running || exit 1
    if [ "$CMD_IS_GDB" == "1" ]; then
        eval $SUDO_PREFIX $CMD_PREFIX $BIN_PATH $*
    else
        eval $SUDO_PREFIX $CMD_PREFIX $PERF_PREFIX $BIN_PATH $* &
    fi
}

function cmdctl_server_stop {
    echo "***** Stopping ${PROC_NAME} server..."
    cmdctl_server_check_running || return 0
    COUNTER=0
    cmdctl_server_killall -SIGTERM || COUNTER=10
    while [ "`cmdctl_server_first_pid`" != "" ]
    do
        if [ $COUNTER -eq 10 ]; then
                cmdctl_server_killall -SIGKILL
            break
        fi
        sleep 1
        COUNTER=$(($COUNTER + 1))
    done
    return 0
}

function cmdctl_server_cleanup {
    cmdctl_server_stop || return 1
    [ ! -z $LOGDIR ] && eval $SUDO_PREFIX find $LOGDIR/ -maxdepth 1 -type f -exec "rm -f {} \;"
    [ ! -z $LOGDIR ] && eval $SUDO_PREFIX find $LOGDIR/ -maxdepth 1 -type s -exec "rm -f {} \;"
}

function cmdctl_server_restart {
    ./serverctl cleanup || return 1
    ./serverctl start $*
}

function cmdctl_server_frestart {
    ./serverctl cleanup || return 1
    ./serverctl killport || true
    ./serverctl start $*
}

function cmdctl_server_ps_wrapped {
    local wrapper=$1
    shift
    PS_OUT=$( ps --sort=start_time ${2} -eo ${1},user,args | grep "$(whoami)" | grep -e $BIN_PATH -e $wrapper | grep -v grep )
    if [ "$PS_OUT" != "" ]; then
        echo "$PS_OUT" | awk "{ printf(\"$PROC_NAME %s %s $PROC_NAME\n\", \$1, \$2) }"
        return 1
    fi
    return 0
}

function cmdctl_server_ps_raw {
    if [ -f .tmp/valgrind.out ]; then
        cmdctl_server_ps_wrapped valgrind.bin $* || return 0
    fi
    cmdctl_server_ps $*
}

function __cmdctl_server_ps {
    cmdctl_server_ps_raw $* | grep -e "^${PROC_NAME}" -e "^exe\s" | awk '{ sub(/<defunct>/, "") }; 1'
}

function cmdctl_server_ps {
    ps --sort=start_time ${2} -eo comm,${1},user,args | grep "$(whoami)" | grep $BIN_PATH | grep -v grep
}

function cmdctl_server_ps_pids {
    __cmdctl_server_ps pid
}

function cmdctl_server_ps_tids {
    __cmdctl_server_ps tid H
}

function cmdctl_server_ps_pids_tids {
    __cmdctl_server_ps pid,tid H
}

function cmdctl_server_status {
    echo "***** Status of the $PROC_NAME server:"
    cmdctl_server_check_running || return 0
    cmdctl_server_ps_pids
}

function cmdctl_server_pids_from_root_pid {
    info_proc_hierarchy_ps $1 1 pid
}

function cmdctl_pid_filter {
    local pids=$( eval $* || return 1 )
    if [ "$pids" == "" ]; then
        return
    fi
    if [ $CMDCTL_PIDFILTER_H -eq 1 ]; then
         for pid in $pids
         do
             cmdctl_server_pids_from_root_pid $pid
         done
         return
    fi
    echo "$pids"
}

function cmdctl_server_pids {
    cmdctl_server_ps_pids | awk '{ print $2; }'
}

function cmdctl_server_tids {
    cmdctl_server_ps_tids | awk '{ print $2; }'
}

function cmdctl_server_pids_tids {
    cmdctl_server_ps_pids_tids | awk '{ print $2,$3; }'
}

function cmdctl_server_first_pid {
    cmdctl_server_pid_num pid1
}

function cmdctl_server_pid_num {
    local num=$( echo $1 | sed "s/[^n0-9]*//g" )
    cmdctl_server_id_num pids $num
}

function cmdctl_server_tid_num {
    local num=$( echo $1 | sed "s/[^n0-9]*//g" )
    cmdctl_server_id_num tids $num
}

function cmdctl_server_ptid_num {
    local num=$( echo $1 | sed "s/[^n0-9]*//g" )
    cmdctl_server_id_num ptids $num
}

function cmdctl_server_check_pid {
    $SUDO_PREFIX kill -0 $1 &> /dev/null && echo $1
}

function cmdctl_server_id_num {
    local action=$1
    local num=$2
    local ctl=./serverctl
    if [ ! -f ./serverctl ]; then
        ctl=./clientctl
    fi
    if [ "$num" == "n" ]; then
        eval $ctl $action | tail -n 1
    else
        eval $ctl $action | awk NR==$num
    fi
}

function cmdctl_server_udscmd {
    local file=$CMDDIR/$1.cmd.$PID
    shift || return 1
    echo $* | nc -U $file
}

function cmdctl_server_port {
    echo 1080 # We use 1080 by default
}

function cmdctl_server_netstat {
    local server_port=$( ./serverctl port )
    sudo netstat -nap | grep :${server_port} | grep "LISTEN "
}

function cmdctl_server_kill_port {
    local server_port=$( ./serverctl port )
    local server_netstat=$( cmdctl_server_netstat )
    local info=$( echo "$server_netstat" | sed "s/^.*LISTEN *\([^ ]*\).*$/\1/g" )
    if [ "$info" == "" ]; then
        echo "***** No server found on port $server_port..."
        return
    fi
    local pid=$( echo "$info" | awk -F / '{ print $1}' )
    local name=$( echo "$info" | awk -F / '{ print $2}' )
    if [ "$name" == "" ]; then
        name="UNKNOWN"
    fi
    echo "***** Killing server '$name' (pid=$pid) on port $server_port..."
    local counter=0
    sudo kill -SIGTERM $pid || counter=10
    while sudo kill -0 $pid &> /dev/null
    do
        if [ $counter -eq 10 ]; then
            sudo kill -SIGKILL $pid
            break
        fi
        sleep 0.5
        counter=$(($counter + 1))
    done
}

function cmdctl_server_action {
    local mode=$1
    local mode_noh=${mode%-h}
    shift || true
    export CMDCTL_PIDFILTER_H=0
    if [ "$mode" != "$mode_noh" ]; then
        export CMDCTL_PIDFILTER_H=1
        mode=$mode_noh
    fi
    case $mode in
        'start')
          cmdctl_server_start $* || return 1
          ;;
        'stop'|'fix')
          cmdctl_server_stop || return 1
          ;;
        'cleanup')
          cmdctl_server_cleanup || return 1
          ;;
        'restart')
          cmdctl_server_restart $* || return 1
          ;;
        'frestart')
          cmdctl_server_frestart $* || return 1
          ;;
        'status')
          cmdctl_server_status || return 1
          ;;
        'pids')
          cmdctl_pid_filter cmdctl_server_pids || return 1
          ;;
        'pid')
          cmdctl_pid_filter cmdctl_server_first_pid || return 1
          ;;
        'tids')
          cmdctl_server_tids || return 1
          ;;
        'ptids')
          cmdctl_server_pids_tids || return 1
          ;;
         pid[n0-9]*)
          cmdctl_pid_filter cmdctl_server_pid_num $mode || return 1
          ;;
         tid[n0-9]*)
          cmdctl_server_tid_num $mode || return 1
          ;;
         ptid[n0-9]*)
          cmdctl_server_ptid_num $mode || return 1
          ;;
         [0-9]*)
          cmdctl_pid_filter cmdctl_server_check_pid $mode || return 1
          ;;
        'port')
          cmdctl_server_port || return 1
          ;;
        'netstat')
          cmdctl_server_netstat || return 1
          ;;
        'killport')
          cmdctl_server_kill_port || return 1
          ;;
        'testxl')
          ${ROOT}/apps/scripts/xl/testrun.sh || return 1
          ;;
        *)
          cmdctl_cmd_action $mode $* || return 1
          ;;
    esac
    return 0
}

function cmdctl_client_testdeps {

    for tool in $RUN_DEPS; do
        which $tool &>/dev/null || return 1
    done

    return 0

}

function cmdctl_client_run {
    if [ -f ./runclient ]; then
        cmdctl_client_testdeps || (echo "One or more missing tools: $RUN_DEPS. Unable to run test." ; return 1) || return 2
        echo "***** Running $PROC_NAME test run..."
        ./runclient || return 1
    else
        echo "Unsupported action: run"
        return 2
    fi
    return 0
}

function cmdctl_client_bench {
    if [ -f ./runbench ]; then
        echo "***** Running $PROC_NAME benchmark..."
        ./runbench $1 || return 1
    else
        echo "Unsupported action: bench"
        return 2
    fi
    return 0
}

function cmdctl_client_cleanup {
    [ ! -z $LOGDIR ] && eval $SUDO_PREFIX rm -f $LOGDIR/*
}

function cmdctl_client_pingst {
    eval $SUDO_PREFIX ../../bin/stctl ping `./serverctl pid`
}

function cmdctl_client_testst {
    eval $SUDO_PREFIX $TESTST_PREFIX ../scripts/st/clienttestst.sh `./serverctl pid` `./serverctl bin`
}

function cmdctl_client_dumpqp {
    eval $SUDO_PREFIX ${ROOT}/apps/scripts/qprof/clientdump.sh `./serverctl pid` $LOGDIR $CMDDIR
}

function cmdctl_client_profqp {
    eval $SUDO_PREFIX ${ROOT}/apps/scripts/qprof/clientprof.sh
}

function cmdctl_client_qpcmd {
    eval $SUDO_PREFIX ${ROOT}/apps/scripts/qprof/clientcmd.sh `./serverctl pid` $LOGDIR $CMDDIR $*
}

function cmdctl_client_dumpcp {
    eval $SUDO_PREFIX ${ROOT}/apps/scripts/cp/clientdump.sh $1 $LOGDIR
}

function cmdctl_client_statcp {
    eval $SUDO_PREFIX bash ${ROOT}/apps/scripts/cp/stat.sh $1 $2 $LOGDIR
}

function cmdctl_client_xlcmd {
    eval $SUDO_PREFIX ${ROOT}/apps/scripts/xl/clientcmd.sh `./serverctl pid` $LOGDIR $CMDDIR $*
}

function cmdctl_client_action {
    mode=$1
    shift || true
    case $mode in
        'run')
          cmdctl_client_run || return 1
          ;;
        'bench')
          cmdctl_client_bench $1 || return 1
          ;;
        'cleanup')
          cmdctl_client_cleanup || return 1
          ;;
         pids|pid|tids|ptids|pid[n0-9]*|tid[n0-9]*|ptid[n0-9]*|[0-9]*)
          if [ -f ./serverctl ]; then
              ./serverctl $mode $*
          else
              cmdctl_server_action $mode $* || return 1
          fi
          ;;
        'pingst')
          cmdctl_client_pingst || return 1
          ;;
        'testst')
          cmdctl_client_testst || return 1
          ;;
        'panalysis')
          cmdctl_client_panalysis || return 1
          ;;
        'dumpqp')
          cmdctl_client_dumpqp || return 1
          ;;
        'profqp')
          cmdctl_client_profqp || return 1
          ;;
        'qpcmd')
          cmdctl_client_qpcmd $* || return 1
          ;;
        'statcp')
          cmdctl_client_statcp $* || return 1
          ;;
        'dumpcp')
          cmdctl_client_dumpcp $* || return 1
          ;;
        'xlcmd')
          cmdctl_client_xlcmd $* || return 1
          ;;
        *)
          cmdctl_cmd_action $mode $* || return 1
          ;;
    esac
    return 0
}

SUDO_PREFIX=""
TESTST_PREFIX=""
CMD_IS_GDB=0

#
# Run-time configurations
#
LOGDIR=$(pwd)/.tmp
CMDDIR=$(pwd)/.tmp

. ${ROOT}/apps/scripts/include/perf.inc

if [ ! -d $LOGDIR ]; then
    mkdir $LOGDIR
    chmod 777 $LOGDIR
fi
if [ ! -d $CMDDIR ]; then
    mkdir $CMDDIR
fi
(mkfifo $CMDDIR/__fifochk &>/dev/null && rm -f $CMDDIR/__fifochk) || CMDDIR=/tmp

COMMON_PREFIX="LOGDIR=$LOGDIR CMDDIR=$CMDDIR SEGFAULT_OUTPUT_NAME=$LOGDIR/segfault.out PROC_NAME=$PROC_NAME $PERF_CMD_PREFIX"

if [ "$RUN_PIN" != "" ]; then
    CMD_PREFIX="$COMMON_PREFIX $( readlink -f ${ROOT}/apps/scripts/pin/run.sh )"

elif [ "$GDB_PIN" != "" ]; then
    CMD_PREFIX="$COMMON_PREFIX $( readlink -f ${ROOT}/apps/scripts/pin/gdb.sh )"
    CMD_IS_GDB=1

elif [ "$RUN_EINSTEIN" != "" ]; then
    CMD_PREFIX="$COMMON_PREFIX $( readlink -f ${ROOT}/apps/scripts/einstein/run.sh )"

elif [ "$GDB_EINSTEIN" != "" ]; then
    CMD_PREFIX="$COMMON_PREFIX $( readlink -f ${ROOT}/apps/scripts/einstein/gdb.sh )"
    CMD_IS_GDB=1

elif [ "$GDB" == "1" ]; then
    CMD_PREFIX="$COMMON_PREFIX $( readlink -f ${ROOT}/apps/scripts/generic/gdb.sh )"
    CMD_IS_GDB=1

elif [ "$RUN_CUSTOM" != "" ]; then
    CMD_PREFIX="$COMMON_PREFIX $RUN_CUSTOM"

else
    CMD_PREFIX="$COMMON_PREFIX"
fi

if [ "$STRACE" == "1" ]; then
    CMD_PREFIX="$( readlink -f ${ROOT}/apps/scripts/generic/strace.sh ) $CMD_PREFIX"
    CMD_IS_GDB=1

elif [ "$LTRACE" == "1" ]; then
    CMD_PREFIX="$( readlink -f ${ROOT}/apps/scripts/generic/ltrace.sh ) $CMD_PREFIX"
    CMD_IS_GDB=1

elif [ "$MTRACE" == "1" ]; then
    CMD_PREFIX="$( readlink -f ${ROOT}/apps/scripts/generic/mtrace.sh ) $CMD_PREFIX"

elif [ "$VGRIND" == "1" ]; then
    CMD_PREFIX="$( readlink -f ${ROOT}/apps/scripts/generic/valgrind.sh ) $CMD_PREFIX"
    CMD_IS_GDB=1
    touch .tmp/valgrind.out
fi

if [ -n "$CUSTOM_LOADER_SCRIPT" ]; then
    CMD_PREFIX="$CMD_PREFIX $CUSTOM_LOADER_SCRIPT"
fi

if [ "$NEEDS_ROOT_PERM" == "1" ]; then
    SUDO_PREFIX="sudo -E"
    sudo true
fi

