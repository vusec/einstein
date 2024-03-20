#!/bin/bash

set -o errexit
set -o errtrace

PATCH_DB_DIR=${PATCH_DB_DIR:-patch_db}
PATCH_REMOVE_TEMPS=${PATCH_REMOVE_TEMPS:-1}
PATCH_DIFF_OPTS=${PATCH_DIFF_OPTS:--p -N}
PATCH_OPTS=${PATCH_OPTS:-}

PATCH_DIFF_FUNC_REGEX=${PATCH_DIFF_FUNC_REGEX:-"\*{15}\s[a-zA-Z0-9_-]+\("}
PATCH_DIFF_HEADER_REGEX=${PATCH_DIFF_HEADER_REGEX:-"^diff"}
PATCH_DIFF_ADD_REGEX=${PATCH_DIFF_ADD_REGEX:-"^+[^+]"}
PATCH_DIFF_CHG_REGEX=${PATCH_DIFF_CHG_REGEX:-"^\![^\!]"}
PATCH_DIFF_DEL_REGEX=${PATCH_DIFF_DEL_REGEX:-"^-[^-]"}

function patch_exit_usage {
    echo "Usage: [PATCH_DB_DIR=dir PATCH_REMOVE_TEMPS=0|1 PATCH_DIFF_OPTS=opts] patch [action ...]"
    echo " - Available actions: "
    echo "     [list]"
    echo "     [get                     version1 version2]"
    echo "     [getincr                 [ALL|[version1 version2]]]"
    echo "     [file-clean              [ALL|[version1 version2]]]"
    echo "     [file-apply              [ALL|[version1 version2]]]"
    echo "     [file-unapply            [ALL|[version1 version2]]]"
    echo "     [file-filter-include     [ALL|[version1 version2]] regex], e.g., regex=\\\\.[ch]"
    echo "     [file-filter-exclude     [ALL|[version1 version2]] regex], e.g., regex=win32.*"
    echo "     [file-stats              [ALL|[version1 version2]]]"
    echo "     [file-summary            [ALL|[version1 version2]]]"
    echo "     [file-meldcmd            [ALL|[version1 version2]]]"
    echo "     [sbindiff-stats          [version1 version2] [incr]]"

    exit 1
}

function patch_list_sort {
    local tmp_file=`mktemp -t patch.inc.patch_list_sort.XXXXXX`
    while read data
    do
      echo "$data" >> $tmp_file
    done
    cat $tmp_file | sort -t \. -n -k1,1 -k2,2 -k3,3 -k4,4
    rm -f $tmp_file
}

function patch_version_to_url {
    echo "$PATCH_URL/${PATCH_PROG_PREFIX}$1${PATCH_PROG_SUFFIX}"
}

function patch_url_to_local_dir {
    local url=$1
    local dir=$2
    local tmp_dir=`mktemp -dt patch.inc.url_to_local_dir.XXXXXX`
    echo "*** Fetching url ${url}..." 1>&2
    cd $tmp_dir
    wget -O app${PATCH_PROG_SUFFIX} -q $url
    tar xvfz app${PATCH_PROG_SUFFIX} > /dev/null
    rm -f app${PATCH_PROG_SUFFIX}
    eval "cp -r */* $dir"
}

function patch_list {
    wget -O index.html -q ${PATCH_URL}/
    cat index.html | grep ${PATCH_PROG_PREFIX}.*${PATCH_PROG_SUFFIX} | sed "s/.*${PATCH_PROG_PREFIX}\(.*\)${PATCH_PROG_SUFFIX}.*/\1/g" | patch_list_sort | uniq
    rm -f index.html
}

function patch_get {
    if [ $# -ne 2 ]; then
        patch_exit_usage
    fi
    local version1=$1
    local version2=$2
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}.patch
    local dir1=`mktemp -dt patch.inc.get1.XXXXXX`
    local dir2=`mktemp -dt patch.inc.get2.XXXXXX`
    echo "*** Creating patch ${patch_name}..."
    $(patch_url_to_local_dir $(patch_version_to_url $version1) $dir1)
    $(patch_url_to_local_dir $(patch_version_to_url $version2) $dir2)
    local ret=0
    echo "*** Running diff $PATCH_DIFF_OPTS --text -r $dir1 $dir2"
    diff $PATCH_DIFF_OPTS --text -r $dir1 $dir2 > $patch_name || ret=$?
    if [ $PATCH_REMOVE_TEMPS -eq 1 ]; then
        rm -rf `dirname $dir1`/patch.inc.*
    fi
    if [ $ret -ne 1 ]; then
        echo "diff returned unexpected exit status $ret!"
        exit 1
    fi
}

function patch_get_from_list {
    local patch_list_string=$*
    local patch_array=($patch_list_string)
    local patch_count=$((${#patch_array[@]} - 1))
    local index=0
    local new_index=0
    echo "***** Creating patches for list: ${patch_list_string}..."
    while [ "$index" -lt "$patch_count" ]; do
    	new_index=$(( $index + 1 ))
        patch_get ${patch_array[$index]} ${patch_array[$new_index]}
        index=$new_index
    done
}

function patch_get_all {
    local patch_list_string=$(patch_list | xargs)
    patch_get_from_list "$patch_list_string"
}

function patch_get_incr {
    if [ "$1" == "ALL" ]; then
        patch_get_all
        return
    fi
    if [ $# -ne 2 ]; then
        patch_exit_usage
    fi
    local version1=$1
    local version2=$2
    local patch_list_string=$(patch_list | xargs)
    patch_list_string=$(echo " $patch_list_string " | sed "s/.* \($version1 .*\)/\1/g" | sed "s/\(.* $version2\) .*/\1/g")
    patch_get_from_list "$patch_list_string"
}

function __patch_file_list {
    for f in `ls $PATCH_DB_DIR/*.patch`
    do
        basename $f | sed 's/\.patch//;s/_/\n/'
    done
}

function patch_file_list {
    __patch_file_list | patch_list_sort | uniq
}

function patch_file_apply {
    if [ "$1" == "ALL" ]; then
        shift
        patch_file_foreach patch_file_apply 0 $*
        return
    fi
    if [ $# -ne 2 ]; then
        patch_exit_usage
    fi
    local version1=$1
    local version2=$2
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}.patch
    patch $PATCH_OPTS -p3 < $patch_name
}

function patch_file_unapply {
    if [ "$1" == "ALL" ]; then
        for line in $( git diff --name-only HEAD -- . )
        do
            echo Would restore $line
        done
        git clean -fdn -- .
        echo Continue?
        read X
        git checkout -- .
        git clean -fd -- .
        return
    fi
    if [ $# -ne 2 ]; then
        patch_exit_usage
    fi
    local version1=$1
    local version2=$2
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}.patch
    patch $PATCH_OPTS -R -p3 < $patch_name
}

function patch_file_clean {
    if [ "$1" == "ALL" ]; then
        rm -f $PATCH_DB_DIR/*.patch
        return
    fi
    if [ $# -ne 2 ]; then
        patch_exit_usage
    fi
    local version1=$1
    local version2=$2
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}.patch
    rm -f $patch_name
}

function patch_file_foreach {
    local action=$1
    local num_args=$2
    shift; shift
    if [ $# -ne $num_args ]; then
        patch_exit_usage
    fi
    local steps_to_next_action=1
    for v in `__patch_file_list`
    do
    	if [ $steps_to_next_action -gt 0 ]; then
             steps_to_next_action=$(( $steps_to_next_action - 1 ))
        else
            echo "Running: $action $last_version $v $*"
            eval '$action $last_version $v $*'
            steps_to_next_action=1
        fi
        last_version=$v
    done
}

function patch_file_filter {
    local from=$1
    shift
    if [ "$1" == "ALL" ]; then
        shift
        patch_file_foreach $from 1 $*
        return
    fi
    if [ $# -ne 3 ]; then
        patch_exit_usage
    fi
    if [ $from == patch_file_filter_exclude ]; then
        is_exclude=1
        is_include=0
    else
        is_exclude=0
        is_include=1
    fi
    local version1=$1
    local version2=$2
    local filter=$3
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}
    gawk "/${PATCH_DIFF_HEADER_REGEX} / { p=$is_exclude } /${PATCH_DIFF_HEADER_REGEX}.*${filter}$/ { p=$is_include } // { if (p==1) { print } }" $patch_name.patch > $patch_name.filter.patch
    if ! diff $patch_name.patch $patch_name.filter.patch &> /dev/null; then
        echo "*** Excluded files: "
        cat $patch_name.patch | grep "${PATCH_DIFF_HEADER_REGEX}" > $patch_name.patch.header
        cat $patch_name.filter.patch | grep "${PATCH_DIFF_HEADER_REGEX}" > $patch_name.filter.patch.header
        diff $patch_name.patch.header $patch_name.filter.patch.header | grep diff
        mv $patch_name.filter.patch $patch_name.patch
    else
        rm -f $patch_name.filter.patch
    fi
    rm -f $PATCH_DB_DIR/*.patch.header
}

function patch_file_filter_exclude {
    patch_file_filter patch_file_filter_exclude $*
}

function patch_file_filter_include {
    patch_file_filter patch_file_filter_include $*
}

function patch_file_stats {
    if [ "$1" == "ALL" ]; then
        shift
        patch_file_foreach patch_file_stats 0 $*
        return
    fi
    if [ $# -ne 2 ]; then
        patch_exit_usage
    fi
    local version1=$1
    local version2=$2
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}.patch
    local files_changed=$(grep "${PATCH_DIFF_HEADER_REGEX}" $patch_name | wc -l)
    local func_changed=$(grep -E "${PATCH_DIFF_FUNC_REGEX}" $patch_name | uniq | wc -l)
    local loc_added=$(grep "${PATCH_DIFF_ADD_REGEX}" $patch_name | wc -l)
    local loc_changed=$(grep "${PATCH_DIFF_CHG_REGEX}" $patch_name | wc -l)
    local loc_removed=$(grep "${PATCH_DIFF_DEL_REGEX}" $patch_name | wc -l)
    local loc_total=$(( $loc_added + $loc_changed + $loc_removed ))
    echo "*** Stats for $patch_name:"
    echo " - Files changed: $files_changed"
    echo " - Functions changed: $func_changed"
    echo " - LOC added: $loc_added"
    echo " - LOC changed: $loc_changed"
    echo " - LOC removed: $loc_removed"
    echo " - LOC total: $loc_total"
}

function patch_file_summary {
    if [ "$1" == "ALL" ]; then
        shift
        patch_file_foreach patch_file_summary 0 $*
        return
    fi
    if [ $# -ne 2 ]; then
        patch_exit_usage
    fi
    local version1=$1
    local version2=$2
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}.patch
    echo "*** Summary for $patch_name:"
    grep -e "${PATCH_DIFF_HEADER_REGEX}" -e "${PATCH_DIFF_FUNC_REGEX}" $patch_name
}

function patch_file_meldcmd {
    if [ "$1" == "ALL" ]; then
        shift
        patch_file_foreach patch_file_meldcmd 0 $*
        return
    fi
    if [ $# -ne 2 ]; then
        patch_exit_usage
    fi
    local tmp_file=`mktemp -t patch.inc.file_meldcmd.XXXXXX`
    local version1=$1
    local version2=$2
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}.patch
    echo -n meld
    cat $patch_name | grep $PATCH_DIFF_HEADER_REGEX > $tmp_file
    while read line
    do
        files=`echo $line | sed "s/^diff.* -r //g"`
        echo -n " --diff "
        for file in $files; do
            if [ -f $file ]; then
                echo -n $file
                echo -n " "
            else
                echo -n "/dev/null "
            fi
        done
    done < $tmp_file
    echo ""
}

function __patch_sbindiff {
    local version1=$1
    local version2=$2
    local bins_dir=$3
    local logs_dir=$4

    # compile the Version 1.
    # If the directory already exists, we assume that the version1 was
    # already compiled.
    if [ ! -d ${bins_dir}/${version1}/ ]; then
        mkdir -p ${bins_dir}/${version1}/

        echo "***** Compile version ${version1}"
        ./configure.llvm > /dev/null
        make -s clean && make -s install && \
          cp $BIN_PATH ${bins_dir}/$version1/  > /dev/null && \
          cp $BC_PATH ${bins_dir}/$version1/  > /dev/null
    fi

    # retrieve the patch
    local patch_name=$PATCH_DB_DIR/${version1}_${version2}.patch
    patch_get ${version1} ${version2}
    patch $PATCH_OPTS -p3 < $patch_name

    # Apply the patch and compile the new version of the server.
    mkdir -p ${bins_dir}/${version2}/ > /dev/null
    mkdir -p ${logs_dir}/${version1}_${version2}/ > /dev/null

    echo "***** Compile version ${version2}"
    ./configure.llvm > /dev/null
    make -s clean && make -s install && \
      cp $BIN_PATH ${bins_dir}/${version2}/ > /dev/null && \
      cp $BC_PATH ${bins_dir}/${version2}/ > /dev/null 

    echo "***** Producing statistics for ${version1} vs. ${version2}"
    cd $llvm_bin_dir
        # without renaming detection
        if [ "$BC_PATH" != "" ]; then
            echo "*** LLVM (renaming detection=OFF)"
            ./sbindiff.sh -s $logs_dir/${version1}_${version2}/llvm.log \
              -t llvm \
              -o ${bins_dir}/${version1}/$PROC_NAME.bc \
              -n ${bins_dir}/${version2}/$PROC_NAME.bc > /dev/null
        else
            echo "*** WARNING: LLVM skipped (renaming detection=OFF)"
        fi

        echo "*** BIN (renaming detection=OFF)"
        ./sbindiff.sh -s $logs_dir/${version1}_${version2}/bin.log \
          -t bin \
          -o ${bins_dir}/${version1}/$PROC_NAME \
          -n ${bins_dir}/${version2}/$PROC_NAME > /dev/null
        echo "*** ASM (renaming detection=OFF)"
        ./sbindiff.sh -s $logs_dir/${version1}_${version2}/asm.log \
          -t asm \
          -o ${bins_dir}/${version1}/$PROC_NAME \
          -n ${bins_dir}/${version2}/$PROC_NAME > /dev/null

        # with renaming detection
        if [ "$BC_PATH" != "" ]; then
            echo "*** LLVM (renaming detection=ON)"
            ./sbindiff.sh -r \
              -s $logs_dir/${version1}_${version2}/llvm_renamed.log \
              -t llvm \
              -o ${bins_dir}/${version1}/$PROC_NAME.bc \
              -n ${bins_dir}/${version2}/$PROC_NAME.bc > /dev/null
        else
            echo "*** WARNING: LLVM skipped (renaming detection=OFF)"
        fi
        echo "*** BIN (renaming detection=ON)"
        ./sbindiff.sh -r -s $logs_dir/${version1}_${version2}/bin_renamed.log \
          -t bin \
          -o ${bins_dir}/${version1}/$PROC_NAME \
          -n ${bins_dir}/${version2}/$PROC_NAME > /dev/null
        echo "*** ASM (renaming detection=ON)"
        ./sbindiff.sh -r -s $logs_dir/${version1}_${version2}/asm_renamed.log \
          -t asm \
          -o ${bins_dir}/${version1}/$PROC_NAME \
          -n ${bins_dir}/${version2}/$PROC_NAME > /dev/null
    cd - > /dev/null
}

function patch_sbindiff_stats {
    # ----
    # This function assumes that version1 is the current version of the
    # application on which the diffing is performed.
    # ----

    if [ "$BC_PATH" == "" ]; then
      echo ""
      echo "**** Warning: \$BC_PATH is not set, hence LLVM diffing " \
           "will be skipped"
    fi

    # check for the availability of the tool
    local llvm_bin_dir=../../bin/
    if [[ ! -x "$llvm_bin_dir/sbindiff" || ! -f "$llvm_bin_dir/sbindiffy.so" ]]
    then
      echo "+---"
      echo "+ Error"
      echo "+"
      echo "+ to run this action you need to first compile"
      echo "+ 'sbindiff' and the 'sbinidffy.so' pass."
      echo "+ see: https://github.com/cgiuffr/llvm-apps/wiki/Building-and-using-sbindiff"
      echo "+---"
      return
    fi

    # parse the parameters
    local version1=$1
    local version2=$2
    local incr=$(echo "$3" | tr "[A-Z]" "[a-z]")

    # prepare the statitics directory
    local suffix=$(date "+%Y%m%d%H%M%S")
    local stats_dir=$(pwd)/stats_${suffix}
    local bins_dir=${stats_dir}/bins/
    local logs_dir=${stats_dir}/logs/

    if [ "$incr" == "incr" ]; then
      local patch_list_string=$(patch_list | xargs)
      patch_list_string=$(echo " $patch_list_string " | \
          sed "s/.* \($version1 .*\)/\1/g" | \
          sed "s/\(.* $version2\) .*/\1/g")
      patch_get_from_list "$patch_list_string"
      
      local prev=""
      local patch_array=($patch_list_string)
      local patch_count=$((${#patch_array[@]} - 1))
      local index=0
      local new_index=0
      echo "***** Generating sbindiff stats from list: ${patch_list_string}..."

      while [ "$index" -lt "$patch_count" ]; do
        next=$(( $index + 1 ))
        echo "***** Diffing ${patch_array[$index]} vs ${patch_array[$next]}"
        __patch_sbindiff ${patch_array[$index]} ${patch_array[$next]} \
            ${bins_dir} ${logs_dir}
        index=$next
      done
    elif [ "$incr" == "" ]; then
        __patch_sbindiff ${version1} ${version2} ${bins_dir} ${logs_dir}
    else
        echo "*** Unrecognized option: $incr"
        patch_exit_usage
    fi

    echo "***** Diffing completed"
    echo "*** Compiled versions: $bins_dir"
    echo "*** Stats collected:   $logs_dir"
    echo "***"
    echo "*** To clean the project, run 'git stash'"
}

function patch_build_delta_versions {
    if [ "$#" -ne 1 ]; then
      echo "Please provide a patch-name" >&2
      echo "{patch_name}_fix.patch is expected in patch_db and {patch_name}_setup.patch is optional." >&2
      return 0
    fi

    local patch_name=$1

    local original_bc="$(pwd)/original_${BC_PATH##*/}"
    local patched_bc="$(pwd)/patched_${BC_PATH##*/}"
    local deltafied_bc="$(pwd)/deltafied_${BC_PATH##*/}"
    rm -f "$original_bc" "$patched_bc" "$deltafied_bc"

    echo "***** Applying setup patch"
    local patch_file="${PATCH_DB_DIR}/${patch_name}.setup"
    if [ -f "$patch_file" ]; then
      patch $PATCH_OPTS -p1 < "$patch_file"
    fi

    echo "***** Disable __LINE__ macros"
    disable_line_macros .

    echo "***** Compiling original version"
    ./configure.llvm && make -s clean && ./relink.llvm deltastub && cp ${BC_PATH} ${original_bc}

    echo "***** Applying patch"
    local patch_file="${PATCH_DB_DIR}/${patch_name}.patch"
    patch $PATCH_OPTS -p1 < "$patch_file"

    echo "***** Compiling patched version: ${patch_name}"
    ./configure.llvm  && make -s clean && ./relink.llvm deltastub && cp ${BC_PATH} ${patched_bc}

    echo "***** Re-enable __LINE__ macros"
    enable_line_macros .

    echo "***** Preparing source tree for debugging (patched_${SRC_DIR})"
    for f in $(lsdiff -p 1 $1 2> /dev/null);
    do
      pf=$(dirname $f)/patched_$(basename $f)
      #rm "$pf"
      #cp "$f" "$pf"
      echo "cp $f $pf"
    done
    patch $PATCH_OPTS --reverse -p1 < "$patch_file"

    echo "***** Done"
}

function disable_line_macros {
  FILES=$(find . -type f -regextype posix-extended -regex ".*\.(c|h)" -exec grep -q "__LINE__" {} \; -print)
  # We just hope this 0x00008A9B constant is never actually used in the sourcecode
  echo "$FILES" | xargs sed -i "s|__LINE__|0x00008A9B|"
}

function enable_line_macros {
  FILES=$(find . -type f -regextype posix-extended -regex ".*\.(c|h)" -exec grep -q "0/\*__LINE__\*/" {} \; -print)
  # We just hope this 0x00008A9B constant is never actually used in the sourcecode
  echo "$FILES" | xargs sed -i "s|0x00008A9B|__LINE__|"
}

function patch_action {
    local mode=$1
    shift || mode="no_action"
    if [ ! -e $PATCH_DB_DIR ]; then
        mkdir $PATCH_DB_DIR
    fi
    if [ "$PATCH_URL" == "" ]; then
        echo "No PATCH_URL available!"
        exit 1
    fi

    case "$mode" in
      'list')
        patch_list
        ;;
      'get')
        patch_get $*
        ;;
      'getincr')
        patch_get_incr $*
        ;;
      'file-list')
        patch_file_list
        ;;
      'file-clean')
        patch_file_clean $*
        ;;
      'file-apply')
        patch_file_apply $*
        ;;
      'file-unapply')
        patch_file_unapply $*
        ;;
      'file-filter-include')
        patch_file_filter_include $*
        ;;
      'file-filter-exclude')
        patch_file_filter_exclude $*
        ;;
      'file-stats')
        patch_file_stats $*
        ;;
      'file-summary')
        patch_file_summary $*
        ;;
      'file-meldcmd')
        patch_file_meldcmd $*
        ;;
      'sbindiff-stats')
        patch_sbindiff_stats $*
        ;;
      'build_delta_versions')
        patch_build_delta_versions $*
        ;;
      'disable-line-macros')
        disable_line_macros $*
        ;;
      'enable-line-macros')
        enable_line_macros $*
        ;;
      *)
        patch_exit_usage
        ;;
    esac
}
