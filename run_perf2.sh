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
stat[1]=instructions
stat[2]=instructions,cycles
stat[3]=instructions,iTLB-load-misses,iTLB-loads,L1-icache-load-misses
stat[4]=instructions,branches,branch-misses
stat[5]=instructions,cache-misses,cache-references
stat[6]=instructions,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-stores
stat[7]=instructions,l2_rqsts.code_rd_hit,l2_rqsts.code_rd_miss,l2_rqsts.all_code_rd
stat[8]=instructions,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss
stat[9]=instructions,l2_rqsts.all_demand_miss,l2_rqsts.all_demand_references
stat[10]=instructions,LLC-loads,LLC-load-misses
stat[11]=instructions,LLC-stores,LLC-store-misses
#stat=$stat1
#stat[1]=instructions
#stat[2]=instructions,cycles
#stat[3]=instructions,iTLB-load-misses,iTLB-loads,L1-icache-load-misses
#stat[3]=instructions,branches,branch-misses
#stat[5]=instructions,cache-misses,cache-references
#stat[6]=instructions,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-stores
#stat[7]=instructions,l2_rqsts.code_rd_hit,l2_rqsts.code_rd_miss,l2_rqsts.all_code_rd
#stat[8]=instructions,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss
#stat[9]=instructions,l2_rqsts.all_demand_miss,l2_rqsts.all_demand_references
#stat[10]=instructions,LLC-loads,LLC-load-misses
#stat[11]=instructions,LLC-stores,LLC-store-misses

for s in "${stat[@]}"
do
	echo $s
done
DIR=perf_output
mkdir -p $DIR
for policy in "${!POLICIES[@]}"
do
	if [[ $policy == 'tls' ]]; then
		continue
	fi
	#if [[ -d $DIR/$policy ]]; then
	#	continue
	#fi
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
	envoy -c $policy_prefix/${POLICIES[$policy]} --concurrency 1 > /dev/null 2>&1 &
	sleep 2

	PID=$(ps -C "envoy" -o pid= | tail -1)
	IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,comm | grep worker_0)
	WTID=${worker[0]}
	sudo taskset -pc 1 $PID

	taskset -c 3 wrk --latency -t1 -d130s -R100 'http://0.0.0.0:10000' > $DIR/${policy}/latency-$fcount &
	sleep 2
	for s in "${stat[@]}"
	do
		if [[ $s == "instructions" ]]; then
			sudo perf record -C 1 -e $s -t $WTID -g -o $DIR/${policy}/${s}_record-$fcount -- sleep 5
		else
			sudo perf record -C 1 -e $s -t $WTID -g -o $DIR/${policy}/${s}_record-$fcount -- sleep 5
		fi
		sudo perf stat -C 1 -I 100 -e $s -t $WTID -o $DIR/${policy}/${s}_stat-$fcount -- sleep 5
	done
	#toplev.py -v --no-desc -l1 -I 1000 --thread -p $PID sleep 5 2> $DIR/${policy}/toplev-$fcount

	sudo kill $PID
	sleep 3
done
