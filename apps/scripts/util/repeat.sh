#!/bin/bash

START_SECONDS=$SECONDS

trap repeat_int INT
trap repeat_int USR1

function repeat_stats()
{
    if [ $STATS -eq 0 ]; then
        return 0
    fi
    if [[ ! -s $OUT_FILE ]]; then
        return 1
    fi

    # Sort invidivual columns for median calculation
    COLUMNS=$( grep "^[ ]*[0-9]" $OUT_FILE | head -1 | wc -w )
    if [ $COLUMNS -eq 0 ]; then
        return
    fi
    for c in $(seq 1 $COLUMNS)
    do
        grep "^[ ]*[0-9]" $OUT_FILE | awk "{ print \$$c }" | sort -n > ${OUT_FILE}.$c
    done
    paste -d ' ' $( ls ${OUT_FILE}.* ) > ${OUT_FILE}.sorted

    cat ${OUT_FILE}.sorted | \
    awk "
      BEGIN { }
      NR==1 {
          for (i=1; i<=NF; i++) {
              max[i]=\$i
              min[i]=\$i
          }
      }
      {
          for (i=1; i<=NF; i++) {
              sum[i]+= \$i
              sum2[i]+= \$i*\$i
              if ( min[i] > \$i ) min[i]=\$i
              if ( max[i] < \$i ) max[i]=\$i
              a[i, NR] = \$i
          }
      }
      END {
          for (i=1; i<=NF; i++) {
              mean[i]=sum[i]/NR
              var[i]=(sum2[i]/NR)-(mean[i]*mean[i])
              median[i]=NR%2? a[i, (NR+1)/2] : (a[i, NR/2] + a[i, NR/2+1])/2
          }
          printf(\"%-7s\", \"SECS:\");   for (i=1; i<=NF; i++ ) { printf(\" %12d\", $(( $SECONDS - $START_SECONDS )) ) }; printf(\"\n\")
          printf(\"%-7s\", \"COUNT:\");  for (i=1; i<=NF; i++ ) { printf(\" %12d\", NR) }; printf(\"\n\")
          printf(\"%-7s\", \"SUM:\");    for (i=1; i<=NF; i++ ) { printf(\" $STATS_FORMAT\", sum[i]) }; printf(\"\n\")
          printf(\"%-7s\", \"MEAN:\");   for (i=1; i<=NF; i++ ) { printf(\" $STATS_FORMAT\", mean[i]) }; printf(\"\n\")
          printf(\"%-7s\", \"MIN:\");    for (i=1; i<=NF; i++ ) { printf(\" $STATS_FORMAT\", min[i]) }; printf(\"\n\")
          printf(\"%-7s\", \"MAX:\");    for (i=1; i<=NF; i++ ) { printf(\" $STATS_FORMAT\", max[i]) }; printf(\"\n\")
          printf(\"%-7s\", \"VAR:\");    for (i=1; i<=NF; i++ ) { printf(\" $STATS_FORMAT\", var[i]) }; printf(\"\n\")
          printf(\"%-7s\", \"MEDIAN:\"); for (i=1; i<=NF; i++ ) { printf(\" $STATS_FORMAT\", median[i]) }; printf(\"\n\")
      }"
      rm -f ${OUT_FILE}*
}

function repeat_int()
{
    echo ""
    repeat_stats
    exit 0
}

CMD="$*"
SLEEP_SECS=${SLEEP_SECS:-0.2}
SAMPLES=${SAMPLES:-0}
WATCH=${WATCH:-1}
STATS=${STATS:-1}
STATS_FORMAT=${STATS_FORMAT:-%12.2f}

if [ $SAMPLES -eq 0 ]; then
    SAMPLES=1000000000
fi

TMP_FILE=$(mktemp --tmpdir repeat_tmpXXXXXX)
OUT_FILE=$(mktemp --tmpdir repeat_outXXXXXX)

x=0
while [ $x -lt $SAMPLES ];
do
    eval $CMD > $TMP_FILE || break
    if [ ! -s $TMP_FILE ]; then
        break
    fi
    if [ $WATCH -eq 1 ]; then
         cat $TMP_FILE
    fi
    cat $TMP_FILE 1>> $OUT_FILE
    sleep $SLEEP_SECS
    let x=x+1
done

repeat_stats
