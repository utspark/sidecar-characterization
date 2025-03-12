#!/bin/bash

#docker compose -f run_scripts/docker-compose-socketify.yml up -d

NOTASKSET=''
TASKSET1='taskset -c 10'
TASKSET2='taskset -c 5'

$NOTASKSET envoy -c envoy_filters/policies/envoy-http.yaml --base-id 0 --concurrency 1 > /dev/null 2>&1 &
sleep 1
$NOTASKSET envoy -c envoy_filters/policies/envoy-ratelimit.yaml --base-id 1 --concurrency 1 > /dev/null 2>&1 &
sleep 1

#br_inst_retired:
#  all_branches,cond,cond_ntaken,cond_taken,far_branch,indirect,near_call,near_return,near_taken
#br_misp_retired:
#  all_branches,cond,cond_ntaken,cond_taken,           indirect,                      near_taken
common_stat_name=(all_branches cond cond_ntaken cond_taken indirect near_taken)
unique_stat_name=(far_branch near_call near_return)
stat_types=(inst misp)

#Stats
#s[0]='-d'
#s[1]='-e br_inst_retired.all_branches,br_misp_retired.all_branches,br_inst_retired.cond,br_misp_retired.cond'
#s[2]='-e br_inst_retired.cond_ntaken,br_misp_retired.cond_ntaken,br_inst_retired.cond_taken,br_misp_retired.cond_taken'
#s[3]='-e br_inst_retired.indirect,br_misp_retired.indirect,br_inst_retired.near_taken,br_misp_retired.near_taken'
#s[4]='-e br_inst_retired.far_branch,br_inst_retired.near_call,br_inst_retired.near_return'
#s[5]='-e sw_prefetch_access.nta,sw_prefetch_access.t0,sw_prefetch_access.t1_t2,sw_prefetch_access.prefetchw'
#s[6]='-e frontend_retired.itlb_miss,frontend_retired.l1i_miss,frontend_retired.l2_miss'
#s[7]='-e icache_16b.ifdata_stall,icache_64b.iftag_hit,icache_64b.iftag_miss,icache_64b.iftag_stall'
#s[8]='-e itlb_misses.stlb_hit,itlb_misses.walk_completed,itlb_misses.walk_completed_4k'
s[9]='-e br_misp_retired.all_branches_cost,br_misp_retired.cond_cost,br_misp_retired.cond_ntaken_cost,br_misp_retired.cond_taken_cost'
s[10]='-e br_misp_retired.indirect_call_cost,br_misp_retired.indirect_cost,br_misp_retired.cond_near_taken_cost,br_misp_retired.ret_cost'
#for idx in {1..4}
#do
#	str=''
#	ct=0
#	for cn in common_stat_name
#	do
#		ct=$eval($ct+1)
#		for t in stat_type
#		do
#			str=$str+','+'br_'+$t+'_retired.'+$cn
#		done
#		if [ $ct == 2 ]; then
#			ct=0
#


#ps -C "envoy"
#ps -T -C envoy
PID1=$(ps -C "envoy" -o pid= | head -1)
PID2=$(ps -C "envoy" -o pid= | tail -1)
IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,pid,comm | grep $PID1 | grep worker_0)
WTID1=${worker[0]}
IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,pid,comm | grep $PID2 | grep worker_0)
WTID2=${worker[0]}
curl -sl 0.0.0.0:10001/plaintext;
DIR='stats'
PINNED=''
for f in {1..10}
do
for stat in "${s[@]}"
do
	echo "Getting the $stat stats\n" >> ${DIR}/stat_outputs${PINNED}_$f
	for i in 1 2 3 4 5 10
	do
		echo "Running $i requests\n" >> ${DIR}/stat_outputs${PINNED}_$f

		for k in {1..5}
		do
			sudo perf stat -I 1000 $stat -t $WTID2 -- sleep 1 2>> ${DIR}/stat_outputs${PINNED}_$f &
			sleep 0.3;
			for j in $(seq 1 $i)
			do
				curl -sl 0.0.0.0:10001/plaintext;
			done
			sleep 1
		done
	done
done
done
sudo kill -9 $PID1
sudo kill -9 $PID2
