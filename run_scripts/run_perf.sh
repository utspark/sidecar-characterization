#!/bin/bash
#set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")

export PATH=$PATH:$SCRIPTDIR/../../pmu-tools/:$SCRIPTDIR/../../wrk2/

declare -A POLICIES
policy_prefix=envoy_filters/policies
policy_files=$policy_prefix/*.yaml
for file in ${policy_files[@]}
do
	IFS='/-.' read -ra tag <<< $file
	POLICIES[${tag[3]}]=envoy-${tag[3]}.yaml
done

declare -A stat
#stat[1]=instructions
stat[1]=instructions,cycles,icache_16b.ifdata_stall
stat[2]=instructions,frontend_retired.l1i_miss,frontend_retired.l2_miss,icache_64b.iftag_miss
stat[3]=instructions,iTLB-load-misses,L1-icache-load-misses
stat[4]=instructions,branches,branch-misses
stat[5]=instructions,cache-misses,cache-references
stat[6]=instructions,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-stores
stat[7]=instructions,l2_rqsts.code_rd_hit,l2_rqsts.code_rd_miss,l2_rqsts.all_code_rd
stat[8]=instructions,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss
stat[9]=instructions,l2_rqsts.all_demand_miss,l2_rqsts.all_demand_data_rd
stat[10]=instructions,LLC-loads,LLC-load-misses
stat[11]=instructions,LLC-stores,LLC-store-misses

URL="0.0.0.0:10000"
#URL="127.0.0.1:32080"
CURL="curl -sl 0.0.0.0:10000 --header \"Content-Type: application/json\""

#POLICIES['http_mix']=envoy-http_mix.yaml

# Start application containers
#docker compose -f run_scripts/docker-compose-js_echoserver.yml up -d
docker compose -f run_scripts/docker-compose-socketify.yml up -d

dt=$(date '+%m%d')
DIR=$1_$dt
mkdir -p $DIR
PROT='http'
for policy in "${!POLICIES[@]}"
do
	if [[ $policy == 'demo' || $policy == 'default' ]]; then
		continue
	fi
	if [[ $policy == 'tls' ]]; then
		PROT='https'
	else
		PROT='http'
	fi
	#if [[ -d $DIR/$policy ]]; then
	#	continue
	#fi
	mkdir -p $DIR/$policy

	if test -f $DIR/$policy/latency_r; then
		continue
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

	#taskset -c 3 wrk --latency -t1 -d360s -R1000 "http://$URL/param?query=demo" > $DIR/${policy}/latency_r_${s}_$fcount &
	taskset -c 3 wrk --latency -t1 -d150s -R5000 "$PROT://$URL/plaintext" > $DIR/${policy}/latency_r &
	sleep 10
	LG_PID=$(ps -C "wrk" -o pid= | tail -1)
	for s in "${stat[@]}"
	do
		sudo perf record -C 1 -e $s -t $WTID -g -o $DIR/${policy}/${s}_record -- sleep 10
		#sleep 2
		#taskset -c 3 wrk --latency -t1 -d5s -R100 "http://$URL/param?query=demo" > $DIR/${policy}/latency_r_${s}_$fcount 
		
		sleep 2

		sudo perf stat -C 1 -I 100 -e $s -t $WTID -o $DIR/${policy}/${s}_stat -- sleep 10
		#sleep 2
		#taskset -c 3 wrk --latency -t1 -d5s -R100 "http://$URL/param?query=demo" > $DIR/${policy}/latency_s_${s}_$fcount
		sleep 2
	done
		
	toplev.py -v --no-desc -l1 -I 1000 --thread -p $PID sleep 5 2> $DIR/${policy}/toplev
	sleep 2
	wait $LG_PID

	sudo kill $PID
	sleep 3
done

#Stop all running containers
docker compose -f run_scripts/docker-compose-socketify.yml stop

# Process perf record
for policy in "${!POLICIES[@]}"
do
	cd $DIR/$policy
	recs=instructions*_record*
	for rec in ${recs[@]}
	do
		if [[ -f perf_report_$rec ]]; then
			continue
		fi
		echo $rec
		sudo perf report -i $rec -f > perf_report_$rec
	done
	cd -
done

sudo chown -R $(id -u):$(id -g) $DIR
