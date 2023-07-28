#!/bin/bash
#set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")

export PATH=$PATH:$SCRIPTDIR/../../pmu-tools/:$SCRIPTDIR/../../wrk2/

declare -A POLICIES
policy_prefix=../envoy_filters/policies

if [[ $1 == "all" ]]; then
	policy_files=$policy_prefix/*.yaml
	for file in ${policy_files[@]}
	do
		IFS='/-.' read -ra tag <<< $file
		POLICIES[${tag[6]}]=envoy-${tag[6]}.yaml
	done
else
	policy=$1
	POLICIES[$policy]=envoy-$policy.yaml
fi
#declare -A stat
stat="intel_pt/cyc,mtc=0,cyc_thresh=1,noretcomp/"
mem_opts="-m,512M"
kern_opts="--kcore"
opts="$mem_opts $kern_opts"

CURL="curl -sl 0.0.0.0:10000 --header \"Content-Type: application/json\""

if [[ ! -z $2 ]]; then
	DIR=$2
else
	DIR=intel_pt_output
fi

mkdir -p $DIR

for policy in "${!POLICIES[@]}"
do
	mkdir -p $DIR/$policy
	#echo $policy
	#echo ${POLICIES[$policy]}
	#start envoy
	envoy -c $policy_prefix/${POLICIES[$policy]} --concurrency 1 > /dev/null 2>&1 &
	sleep 2

	PID=$(ps -C "envoy" -o pid= | tail -1)
	IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,comm | grep worker_0)
	WTID=${worker[0]}
	sudo taskset -pc 1 $PID

	sudo perf record $opts -T -g -o $DIR/${policy}/inst_$rate -e $stat -t $WTID -- sleep 10 &
	sleep 2
	$CURL
	taskset -c 3 wrk --latency -t1 -d4s -R10 'http://0.0.0.0:10000' > $DIR/${policy}/latency
	sleep 4

	sudo kill $PID
	sleep 3
done
