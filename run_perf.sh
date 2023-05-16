#!/bin/bash

export PATH=$PATH:~/workspace/research/servicemesh/pmu-tools/:~/workspace/research/servicemesh/cl-wrk2/

declare -A POLICIES
POLICIES=( [default]=envoy-demo.yaml [iptag]=envoy-ip-tag.yaml [iptag5]=envoy-ip-tag5.yaml [iptag10]=envoy-ip-tag10.yaml )

#stat=instructions,cycles
#stat=l2_rqsts.all_demand_miss,LLC-load-misses,LLC-store-misses
stat=cycle_activity.cycles_l2_miss,cycle_activity.stalls_l2_miss
TS=$(date +%s)

DIR=expt_${TS}_${stat}
mkdir $DIR
for policy in "${!POLICIES[@]}"
do
	echo $policy
	echo ${POLICIES[$policy]}
	#start envoy
	envoy -c ${POLICIES[$policy]} --concurrency 2 > /dev/null 2>&1 &
	sleep 2

	PID=$(ps -C "envoy" -o pid= | tail -1)

	wrk --latency -t1 -d11s -R10000 'http://0.0.0.0:10000' > $DIR/${policy}_latency &
	sudo perf record -e $stat -p $PID -g -o $DIR/${policy}_record -- sleep 10
	#toplev.py -v --no-desc -l1 -I 1000 --thread -p $PID sleep 10 2> $DIR/${policy}_toplev

	sudo kill $PID
	sleep 3
done
