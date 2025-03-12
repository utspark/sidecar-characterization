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
#for file in ${policy_files[@]}
#do
#	IFS='/-.' read -ra tag <<< $file
#	POLICIES[${tag[3]}]=envoy-${tag[3]}.yaml
#done

declare -A stat
#stat[1]=instructions
stat[1]=instructions,cycles
stat[2]=instructions,frontend_retired.l1i_miss,frontend_retired.l2_miss,icache_64b.iftag_miss
#stat[3]=instructions,iTLB-load-misses,iTLB-loads,L1-icache-load-misses
#stat[4]=instructions,branches,branch-misses
#stat[5]=instructions,cache-misses,cache-references
#stat[6]=instructions,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-stores
#stat[7]=instructions,l2_rqsts.code_rd_hit,l2_rqsts.code_rd_miss,l2_rqsts.all_code_rd
#stat[8]=instructions,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss
#stat[9]=instructions,l2_rqsts.all_demand_miss,l2_rqsts.all_demand_references
#stat[10]=instructions,LLC-loads,LLC-load-misses
#stat[11]=instructions,LLC-stores,LLC-store-misses

URL="0.0.0.0:10000"
#URL="127.0.0.1:32080"
CURL="curl -sl 0.0.0.0:10000 --header \"Content-Type: application/json\""

#POLICIES['tls']=envoy-tls.yaml

# Start application containers
#docker compose -f run_scripts/docker-compose.yml up -d
docker compose -f run_scripts/docker-compose-socketify.yml up -d

declare -A rates
rates=(['http']=165 ['tcp']=612 ['tls']=540 ['http_mix']=121 ['logging']=153 ['rbac_reject_100']=520)

for policy in "${!rates[@]}"
do
	POLICIES[$policy]=envoy-${policy}.yaml
done

dt=$(date '+%m%d')
DIR=$1_$dt
PROT='http'
mkdir -p $DIR
for policy in "${!POLICIES[@]}"
do
	if [[ $policy == 'tls' ]]; then
		PROT='https'
	else
		PROT='http'
	fi
	mkdir -p $DIR/$policy

	echo $policy
	echo ${POLICIES[$policy]}
	#start envoy
	taskset -c 1 envoy -c $policy_prefix/${POLICIES[$policy]} --concurrency 1 > /dev/null 2>&1 &
	sleep 2

	PID=$(ps -C "envoy" -o pid= | tail -1)
	IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,comm | grep worker_0)
	WTID=${worker[0]}
	#sudo taskset -pc 1 $PID

	#taskset -c 3 wrk --latency -t1 -d400s -R5000 "http://$URL/param?query=demo" > $DIR/${policy}/latency_r_${s}_$fcount &
	for pct in {10..100..10}
	do
		rate=$(( ${rates[$policy]}*$pct ))
		taskset -c 3 wrk --latency -t1 -d60s -R$rate "$PROT://$URL/plaintext" > $DIR/${policy}/latency_r_${s}_$rate &
		sleep 10
		LG_PID=$(ps -C "wrk" -o pid= | tail -1)
		for s in "${stat[@]}"
		do

			sudo perf stat -C 1 -I 100 -e $s -t $WTID -o $DIR/${policy}/${s}_stat-$rate -- sleep 10
			#sleep 2
			#taskset -c 3 wrk --latency -t1 -d5s -R100 "http://$URL/param?query=demo" > $DIR/${policy}/latency_s_${s}_$fcount
			sleep 2
		done
			
		toplev.py -v --no-desc -l1 -I 1000 --thread -p $PID sleep 5 2> $DIR/${policy}/toplev-$rate
		sleep 2
		if ps -p $LG_PID > /dev/null
		then
			wait $LG_PID
		else
			echo "$LG_PID got done early!!"
			ps -C "wrk" -o pid= 
			sleep 15
		fi
	done

	sudo kill $PID
	sleep 3
done

#Stop all running containers
docker compose -f run_scripts/docker-compose-socketify.yml stop

sudo chown -R $(id -u):$(id -g) $DIR
