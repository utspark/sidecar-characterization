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
declare -A stat
stat=instructions
#stat=$stat1

DIR=perf_out
mkdir -p $DIR
for policy in "${!POLICIES[@]}"
do
	if [[ $policy == 'tls' ]]; then
		continue
	fi
	mkdir -p $DIR/$policy
	recs=$DIR/${policy}/${stat}_record*
	fcount=${#recs[@]}
	#start envoy
	envoy -c $policy_prefix/${POLICIES[$policy]} --concurrency 1 > /dev/null 2>&1 &
	sleep 3
	curl -sl 0.0.0.0:10000 --header "Content-Type: application/json"

	PID=$(ps -C "envoy" -o pid= | tail -1)
	IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,comm | grep worker_0)
	WTID=${worker[0]}
	sudo taskset -pc 1 $PID

	for ((i=0; i<10; i++))
	do
		#taskset -c 3 wrk --latency -t1 -d30s -R1000 'http://0.0.0.0:10000' > $DIR/${policy}/latency-$fcount &
		sudo perf record -C 1 -c 1000 -e $stat -t $WTID -g -o $DIR/${policy}/${stat}_record_x$i -- sleep 2 &
		sleep 1
		curl -sl 0.0.0.0:10000 --header "Content-Type: application/json"
		sleep 1
	done

	sudo kill $PID
done
