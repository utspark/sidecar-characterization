#!/bin/bash
set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")

export PATH=$PATH:$SCRIPTDIR/../pmu-tools/:$DCRIPTDIR/../wrk2/

declare -A POLICIES
policy_prefix=envoy_filters/policies
policy_files=$policy_prefix/*.yaml
for file in ${policy_files[@]}
do
	IFS='/-.' read -ra tag <<< $file
	POLICIES[${tag[3]}]=envoy-${tag[3]}.yaml
done

stat1=instructions,cycles,iTLB-load-misses,iTLB-loads,L1-icache-load-misses
stat2=l2_rqsts.all_demand_miss,LLC-load-misses,LLC-store-misses
stat3=L1MPKI

DIR=perf_metrics
mkdir -p $DIR
for policy in "${!POLICIES[@]}"
do
	if [[ $policy == 'tls' ]]; then
		continue
	fi
	mkdir -p $DIR/$policy

	fcount=1
	fname="$DIR/$policy/latency-1"
	if test -f "$fname"; then
		files=$DIR/$policy/latency*
		for file in ${files[@]}
		do
			IFS='-' read -ra tag <<< $file
			if (( ${tag[1]} >= $fcount )); then
				fcount="$((${tag[1]}+1))"
			fi
		done
	fi	

	echo $policy
	echo ${POLICIES[$policy]}
	#start envoy
	envoy -c $policy_prefix/${POLICIES[$policy]} --concurrency 2 > /dev/null 2>&1 &
	sleep 2

	PID=$(ps -C "envoy" -o pid= | tail -1)
	IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,comm | grep worker_0)
	WTID=${worker[0]}
	sudo taskset -pc 1 $PID

	wrk --latency -t1 -d12s -R1000 'http://0.0.0.0:10000' > $DIR/${policy}/latency-$fcount &
	sudo perf record -C 1 -e $stat1 -t $WTID -g -o $DIR/${policy}/${stat}_record-$fcount -- sleep 5
	toplev.py -v --no-desc -l1 -I 1000 --thread -p $PID sleep 5 2> $DIR/${policy}/toplev-$fcount

	sudo kill $PID
	sleep 3
done
