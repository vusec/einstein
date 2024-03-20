#!/bin/bash

set -o errexit

function build_llvm_tool {
	if [ $HAVE_LLVM -eq 0 ]; then
	    tool="/usr/bin/$1"
	else
	    tool="$LLVMGOLD_PREFIX/bin/llvm-$1"
	fi
	echo $tool
}

function build_llvm_libs {
	local LIBS=""
	for a in $*
	do
		LIBS="$LIBS `find $INSTALL_DIR -maxdepth 1 -name ${a}\*.bcc | xargs`"
	done
	echo $LIBS
}

function build_llvm_app_settings {
	if [ -f settings.llvm/$1/$2 ]; then
	    . ./settings.llvm/$1/$2
	fi
}

function build_llvm_check_lto_disable_opt {
	LLVMGOLD_HAS_LTO_DISABLE_OPT=1
	TMP_FILE=`mktemp --tmpdir configure.llvm.inc.XXXXXX`
	echo "int main() { return 0; }" > ${TMP_FILE}.c
	$LLVMGOLD_CC $LLVMGOLD_LDFLAGS $LLVMGOLD_LTO_DISABLE_OPT -o ${TMP_FILE}.out ${TMP_FILE}.c &> /dev/null || LLVMGOLD_HAS_LTO_DISABLE_OPT=0
	rm -f ${TMP_FILE}*
}

if [[ $SANITIZER_BLACKLIST ]]; then
  SANITIZER_BLACKLIST_FLAG="-fsanitize-blacklist=$SANITIZER_BLACKLIST"
fi

# Enable a sanitizer if SANITIZER is set.
case $SANITIZER in
address)
  LLVMGOLD_CFLAGS="$LLVMGOLD_CFLAGS -fsanitize=address $SANITIZER_BLACKLIST_FLAG -fno-omit-frame-pointer"
  LLVMGOLD_LDFLAGS="$LLVMGOLD_LDFLAGS -fsanitize=address"
  ;;
memory)
  LLVMGOLD_CFLAGS="$LLVMGOLD_CFLAGS -fsanitize=memory $SANITIZER_BLACKLIST_FLAG -fno-omit-frame-pointer"
  LLVMGOLD_LDFLAGS="$LLVMGOLD_LDFLAGS -fsanitize=memory "
  ;;
memory_origins)
  LLVMGOLD_CFLAGS="$LLVMGOLD_CFLAGS -fsanitize=memory $SANITIZER_BLACKLIST_FLAG -fno-omit-frame-pointer -fsanitize-memory-track-origins"
  LLVMGOLD_LDFLAGS="$LLVMGOLD_LDFLAGS -fsanitize=memory "
  ;;
*)
  ;;
esac
