#!/bin/bash

export PATH=$PATH:~/workspace/research/servicemesh/pmu-tools/:~/workspace/research/servicemesh/wrk2/

declare -A POLICIES
policy_prefix=envoy_filters/policies
policy_files=$policy_prefix/*.yaml
for file in ${policy_files[@]}
do
	IFS='/-.' read -ra tag <<< $file
	POLICIES[${tag[3]}]=envoy-${tag[3]}.yaml
done
#declare -A stat
stat="intel_pt/cyc,mtc=0,cyc_thresh=1,noretcomp/"
mem_opts="-m,512M"
kern_opts="--kcore"
opts="$mem_opts $kern_opts"

DIR=intel_pt_output
mkdir -p $DIR

#for policy in "${!POLICIES[@]}"
#do
	policy=rbac_reject_10000
	POLICIES[$policy]=envoy-rbac_reject_10000.yaml
	if [[ $policy == 'tls' ]]; then
		continue
	fi
	mkdir -p $DIR/$policy
	echo $policy
	echo ${POLICIES[$policy]}
	#start envoy
	set -x
	envoy -c $policy_prefix/${POLICIES[$policy]} --concurrency 1 > /dev/null 2>&1 &
	sleep 2

	PID=$(ps -C "envoy" -o pid= | tail -1)
	IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,comm | grep worker_0)
	WTID=${worker[0]}
	sudo taskset -pc 1 $PID

	for((i=1 ; i<3 ; i++))
	do
		rate=$(( i*100 ))
		taskset -c 3 wrk --latency -t1 -d10s -R$rate 'http://0.0.0.0:10000' > $DIR/${policy}/latency &
		sleep 4
		sudo perf record $opts -T -g -o $DIR/${policy}/inst_$rate -e $stat -t $WTID -- sleep 2
		sleep 3
	done
	sudo kill $PID
	sleep 3
#done
