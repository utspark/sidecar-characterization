#!/bin/bash

#################################################################
# run wrk load generator for running microservices		#
# cmd-line args: ./run_latency <dir> <app> <max-rate> <step>    #
#################################################################

#set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")

if [ -z $WRK ]; then
	export PATH=$PATH:$SCRIPTDIR/../../pmu-tools/:$SCRIPTDIR/../../wrk2/
fi

DIR=$1
APP=$2
MAX_RATE=$3
STEP=$4
NUM=$(( $MAX_RATE/$STEP ))
mkdir -p $DIR/$APP
for (( i=1; i<=$NUM; i++))
#for i in {1..$MAX_RATE..$STEP}
do
	rate=$(( $i*$STEP ))
	#taskset -c 2,3 wrk --latency -t2 -c2 -d30s -s ./mixed-workload_type_1.lua -R$rate 'http://127.0.0.1:32080' > $DIR/${2}/latency_$rate
	taskset -c 2,4 wrk --latency -t2 -d30s -R$rate 'http://127.0.0.1:32080' > $DIR/$APP/latency_$rate
done
