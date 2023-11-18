#!/bin/bash

#set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")

export PATH=$PATH:$SCRIPTDIR/../../pmu-tools/:$SCRIPTDIR/../../wrk2/

declare -A stat
stat[1]=instructions
stat[2]=instructions,cycles

URL="127.0.0.1:32080"
#URL="127.0.0.1:32080"
CURL="curl -sl 0.0.0.0:10000 --header \"Content-Type: application/json\""

#POLICIES['http_mix']=envoy-http_mix.yaml

#dt=$(date '+%m%d')
#DIR=cycles_$dt
#mkdir -p $DIR
#for policy in "${!POLICIES[@]}"
#do

        #PID=$(ps -C "envoy" -o pid= | tail -1)
        #IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,comm | grep worker_0)
	PIDS=$($SCRIPTDIR/get-details.py -t all)

        #WTID=${worker[0]}
        #sudo taskset -pc 1 $PID

        #for s in "${stat[@]}"
        #do
                #sudo perf record -C 1 -e $s -t $WTID -g -o $DIR/${policy}/${s}_record-$fcount -- sleep 10 &
                #sleep 2
                #taskset -c 3 wrk --latency -t1 -d5s -R100 "http://$URL/param?query=demo" > $DIR/${policy}/latency_r_${s}_$fcount

                #sleep 5
		set -x
                sudo perf stat -I 100 -e cycles:u,cycles:k,instructions:u,instructions:k -p $PIDS --per-thread -o cycle_inst_stat -- sleep 100 &
                #sleep 2
                taskset -c 2,3 wrk --latency -c2 -t1 -d120s -R20 "http://$URL/productpage" > latency
                sleep 2
        #done
        #toplev.py -v --no-desc -l1 -I 1000 --thread -p $PID sleep 5 2> $DIR/${policy}/toplev-$fcount

        #sudo kill $PID
        #sleep 3
#done
