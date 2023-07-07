#!/bin/bash

rate=$1

export PATH=$PATH:/home/prateek/workspace/research/servicemesh/pmu-tools/:/home/prateek/workspace/research/servicemesh/ol-wrk2/

declare -A CORES
CORES=( [1]=1 [2ht]=1,5 [2]=1,2 )

TS=$(date +%s)
DIR=k8sexpt_${TS}_${rate}
mkdir $DIR
PID=$(ps -C "envoy" -o pid= | tail -1)
for cores in "${!CORES[@]}"
do
	echo $cores
	echo ${CORES[$cores]}
	taskset -pc ${CORES[$cores]} $PID
	sleep 2

	stat=instructions,cycles
	#stat=l2_rqsts.all_demand_miss,LLC-load-misses,LLC-store-misses

	taskset -c 3 wrk --latency -t1 -c10 -d11s -R$rate 'http://10.157.90.238:32080/param?query=demo' & #> $DIR/${cores}_latency &
	#sudo perf record -e $stat -p $PID -g -o $DIR/${cores}_${stat}_record -- sleep 10
	toplev.py -v --no-desc -l1 -I 1000 --thread -p $PID sleep 10 2> $DIR/${cores}_toplev

	sleep 3
done
