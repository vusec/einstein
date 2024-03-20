#!/bin/bash

set -e

cd ..
echo "Request number,Time,PSS,Date"

REQNUM=0
while true; do
	((REQNUM=REQNUM+1))
	TIME=$(TIMEFORMAT='%3R'; time ( ./clientctl run &> /dev/null ) 2>&1)
	PSS=$(smem --userfilter=$(whoami) --processfilter=^nginx --columns=pss --totals | tail -1 | sed 's/\s*//g')
	DATE=$(/bin/date +"%F-%T")
	echo "${REQNUM},${TIME},${PSS},${DATE}"
done
