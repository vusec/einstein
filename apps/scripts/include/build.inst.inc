#!/bin/bash

ROOT=${ROOT:-../..}
INSTALL_DIR="${INSTALL_DIR:-${ROOT}/build}"
PIN_ROOT="${PIN_ROOT:-${ROOT}/src/misc/pin-3.28-98749-g6643ecee5-gcc-linux}"

. $ROOT/apps/scripts/include/configure.inst.inc

build_llvm_cmd()
{
	echo "$@" >&2
	"$@"
}

build_llvm_relink_conf_default()
{
	if [ $# -ne 0 ]; then
	    ./configure.llvm "$@"
	fi
}

build_llvm_relink_default()
{
	build_llvm_relink_conf_default "$@"
	make clean install
}

build_llvm_check_conf_file()
{
	if [ ! -f $1 ]; then
	    echo "*** Error: File $1 not found. Run configure.llvm first." >&2
	    exit 1
	fi
}

build_llvm_clean_libs_from_files()
{
	for f in $*
	do
	    build_llvm_clean_libs_from_file $f
	done
}

build_llvm_add_libs_to_files()
{
	local llvm_libs="$1"
	local expr=$2
	shift; shift
	
	for f in $*
	do
	    build_llvm_add_libs_to_file "$llvm_libs" $expr $f
	done
}

build_llvm_clean_libs_from_file()
{
	local file=$1
	local install_dir=`echo ${INSTALL_DIR}/ | sed "s/\\\//\\\\\\\\\//g"`

	build_llvm_check_conf_file $file
	build_llvm_cmd sed -i "s/${install_dir}[^ ]*\.bcc//g" $file
}

build_llvm_add_libs_to_file()
{
	local llvm_libs="$1"
	local expr=$2
	local file=$3

	llvm_libs=`build_llvm_libs $llvm_libs | sed "s/\\\//\\\\\\\\\//g"`
	build_llvm_check_conf_file $file
	build_llvm_cmd sed -i "s/\($expr\)[ ]*/\1 $llvm_libs /g" $file
}

build_llvm_ldlibs_from_file()
{
	local expr=$1
	local file=$2

	build_llvm_check_conf_file $file
	for token in $( grep -- "$expr" $file)
	do
	    echo $token | grep -q "^-l" && echo -n "$token "
	done
	echo
}

build_dr_opts()
{
        DR_PASSES=""
        CNT=0
        for a in $*
        do
            LIB_FILE="$INSTALL_DIR/$a"
            if [ $CNT -ne 0 ]; then
                DR_PASSES+=";"
            fi
            if [ -f "$LIB_FILE" ]; then
                DR_PASSES+="$LIB_FILE;$CNT;"
            else
                DR_PASSES+="$a;$CNT;"
            fi
            CNT=$(( $CNT + 1 ))
        done
        echo -client_lib $DR_PASSES
}

build_di_env_args()
{
        echo DYNINSTAPI_RT_LIB=${DYNINST_RT_LIB} LD_LIBRARY_PATH=${DYNINST_LIB_DIR}:${LD_LIBRARY_PATH}
}

build_di_opt_args()
{
        DI_PASSES=""
        for a in $*
        do
            LIB_FILE="$INSTALL_DIR/$a"
            if [ -f "$LIB_FILE" ]; then
                DI_PASSES+=" -load=$LIB_FILE"
            fi
            DI_PASSES+=$( echo " -$a" | awk -F . '{ print $1; }' )
        done
        build_di_source_env
        echo $INSTALL_DIR/di-opt $DI_PASSES $DI_PASS_ARGS $DI_EXTRA_PASS_ARGS
}

function build_di_source_env {
        local app_dir=$(while ! test -f ./build.llvm; do cd ..; done; pwd )
        local app_env=$app_dir/settings.llvm/di/di.env
        if [ -f $app_env ]; then
            . $app_env
        fi
}

build_di_args()
{
        echo $( build_di_env_args $* ) $( build_di_opt_args $* )
}

build_di()
{
        local input=$1
        local output=$2
        shift; shift
        build_llvm_cmd eval $( build_di_args $* ) -o $output $input
}


build_bini()
{
        if [ $# -eq 0 ]; then
            return
        fi
        if [ ${OUTPUT}.1 -ot ${OUTPUT} ]; then
            cp ${OUTPUT} ${OUTPUT}.1
        fi
	build_di ${OUTPUT}.1 ${OUTPUT} $*
        touch ${OUTPUT}.1
}

build_llvm()
{
	LLVM_PASSES=""
        BINI_ARGS=""
	for a in $*
	do
            if [[ $a = *.[a-z]* ]]; then
                BINI_ARGS+="$a"
                continue
            fi
	    LIB_FILE="$INSTALL_DIR/$a.so"
	    if [ -f "$LIB_FILE" ]; then
		LLVM_PASSES="$LLVM_PASSES -load=$LIB_FILE"
	    fi
	    LLVM_PASSES="$LLVM_PASSES -$a"
	    build_llvm_app_settings build.llvm $a
	done

        if [ "$LLVM_PASSES" == "" ] && [ "$BINI_ARGS" != "" ]; then
            build_bini $BINI_ARGS
            return
        fi

	LLVM_PASSES="$LLVM_PASSES $LLVM_PASS_ARGS"

	if [ "$SKIP_POST_OPTIMIZE" == "1" ]; then
	    LLVMGOLD_OPTFLAGS=`echo $LLVMGOLD_OPTFLAGS | sed "s/-mem2reg//g" | sed "s/-std-compile-opts//g"`
	fi

	build_llvm_cmd $LLVMGOLD_PREFIX/bin/opt $LLVMGOLD_EXTRA_MODULES $LLVM_PASSES $LLVMGOLD_OPTFLAGS $LLVMGOLD_OPTFLAGS_EXTRA -o ${INPUT}.bcl ${INPUT}.bc

	if [ "$EXIT_AFTER_OPT" == "1" ] ;then
	    exit 0
	fi

	if [ "$TRACE_PROCESS" = 1 ]; then
		OUTPUTSUFFIX=.traced
	fi

	if [ $LLVM_TWOSTEP_LINKING_WITH_GOLD -eq 1 ]; then
	    if [ $LLVM_TWOSTEP_LINKING_WITH_GOLD_USES_LLC -eq 1 ]; then
	        INTERMEDIATE=${OUTPUT}.s
	        build_llvm_cmd $LLVMGOLD_PREFIX/bin/llc $LLVMGOLD_LLCFLAGS -o ${INTERMEDIATE} ${INPUT}.bcl
	    else
	        INTERMEDIATE=${OUTPUT}.gold
	        build_llvm_cmd $LINKER $LLVMGOLD_LINK $LLVMGOLD_LINKFLAGS $LLVMGOLD_TSLINK_PARTIALFLAGS -o ${INTERMEDIATE} ${INPUT}.bcl
	    fi
	        rm -f $OUTPUT
		if [ $LLVM_TSLINK_FINAL_USE_GCCBFD == "1" ]; then
		    build_llvm_cmd gcc -fuse-ld=bfd $LLVMGOLD_LINKCOMMONFLAGS $LLVMGOLD_LIBS $LLVMGOLD_LDFLAGS_EXTRA -o ${OUTPUT}${OUTPUTSUFFIX} ${INTERMEDIATE} $LIBS $LLVMGOLD_TSLINK_FINALFLAGS 
		else
		    build_llvm_cmd $LINKER $LLVMGOLD_LINKCOMMONFLAGS $LLVMGOLD_LIBS $LLVMGOLD_TSLINK_FINALFLAGS $LLVMGOLD_LDFLAGS_EXTRA -o ${OUTPUT}${OUTPUTSUFFIX} ${INTERMEDIATE} $LIBS
		fi
	    rm -f ${INTERMEDIATE}
	else
	    rm -f $OUTPUT
	    build_llvm_cmd $LINKER $LLVMGOLD_LDFLAGS $LLVMGOLD_LDFLAGS_EXTRA $LLVMGOLD_FINAL_OPT_FLAGS -o ${OUTPUT}${OUTPUTSUFFIX} ${INPUT}.bcl $LIBS
	fi
	
	if [ "$TRACE_PROCESS" = 1 ]; then
	    $MYPWD/../../erik/tracer/install.sh ${OUTPUT} ${TRACERSETTINGS}
	fi

	if [ "$LLVM_OUTPUT_TRG_DIR" != "" ]; then
	    NEW_OUTPUT=$LLVM_OUTPUT_TRG_DIR/$( basename $OUTPUT )
	    mv -f $OUTPUT $NEW_OUTPUT
	    chmod +x $NEW_OUTPUT
	    ln -s -f $NEW_OUTPUT $OUTPUT
	    OUTPUT=$NEW_OUTPUT
	fi

	LLVM_SETCAP_ARGS=${LLVM_SETCAP_ARGS:-""}
	if [ "$LLVM_SETCAP_ARGS" != "" ]; then
	    build_llvm_cmd sudo setcap $LLVM_SETCAP_ARGS $OUTPUT
	fi

        build_bini $BINI_ARGS
}


