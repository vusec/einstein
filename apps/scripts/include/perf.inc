ROOT=${ROOT:-"../.."}

if [[ -n $PERF  ]]; then

# we need to know where the $INSTALL_DIR IS
. $ROOT/script.inc
make -C $ROOT/llvm/tools/perf install

PERF_MAX_COUNTERS=${PERF_MAX_COUNTERS:-"4"}
PERF_START=${PERF_START:-"0"}

sudo bash -c " echo -1 > /proc/sys/kernel/perf_event_paranoid"

# returns a list of supported counters on this architecture
function perf_get_available_counters {
	$INSTALL_DIR/perf stat -o /dev/stdout -x'=' -e `$INSTALL_DIR/perf list -o /dev/stdout hw cache | awk '$NF>1 {printf("%s,",$1);}'`cycles true 2>&1 | grep -v supp | awk -F = '$NF>1 {printf("%s\n",$2);}'
}

# calculate how many steps are necessary when taking $PERF_MAX_COUNTERS performance counters
function perf_get_necessary_steps {
	echo $[ (`perf_get_available_counters | wc -l` +( $PERF_MAX_COUNTERS - 1)) / PERF_MAX_COUNTERS ]
}

# starting from $1 argument 
function perf_get_counters_range {
	perf_get_available_counters | tail -n+$1 | head -n$PERF_MAX_COUNTERS
}

PERF_EVENTS=`perf_get_counters_range $PERF_START |  awk '{printf("%s,",$1);}'|rev| cut -c 2-|rev`
PERF_OPTS=${PERF_OPTS:-"stat -a -x= "}
PERF_CMD=" $INSTALL_DIR/perf "
PERF_LOGFILE=" -o $LOGDIR/perf.out "
PERF_CMD_PREFIX+=" $PERF_CMD  $PERF_OPTS -e $PERF_EVENTS $PERF_LOGFILE" 
fi


function perf_attach {
	# generate comma seperated list
	PIDS=`./serverctl pids |awk '{printf("%s,", $1);}' | sed 's/,$//'`
	sudo $PERF_CMD record -p $PIDS -e $PERF_EVENTS $PERF_LOGFILE &
}


function perf_bench_all {
	# generate comma seperated list
	PIDS=`./serverctl pids |awk '{printf("%s,", $1);}' | sed 's/,$//'`
	
	if [[ -n $1 ]] ; then
		PERF_COMMAND=$*
	else
		PERF_COMMAND="./clientctl bench"
	fi
	
	rm -f perf.ini

	NECESSARY_STEPS=`perf_get_necessary_steps`

	for i in `seq 1 $NECESSARY_STEPS`; do
		CURRENT_OFFSET=$[ ($i-1) * $PERF_MAX_COUNTERS +1 ]
		PERF_EVENTS=`perf_get_counters_range $CURRENT_OFFSET |  awk '{printf("%s,",$1);}'|rev| cut -c 2-|rev`
		echo PERF_EVENTS: $PERF_EVENTS
		sudo $PERF_CMD $PERF_OPTS -e $PERF_EVENTS $PERF_LOGFILE -- $PERF_COMMAND
		sudo cat .tmp/perf.out |grep "="| awk -F"=" '{printf("  %s=%s\n", $2, $1);}' >> perf.ini
	done
}

function perf_detach {
	sudo killall -SIGINT perf
}

function perf_action {
	mode=$1
	shift || true
	case $mode in 
	  'attach')
		perf_attach $*
		;;
	  'bench_all_counters')
		perf_bench_all $*
		;;
	  'detach')
		perf_detach $*
		;;
	  '')
		echo "Perf_action: Missing command action!"
		return 1
		;;
	  *)
		echo "Perf_action: Invalid action: $mode"
		return 1
		;;
	esac
}
