#!/bin/bash

export PATH=$PATH:~/workspace/research/servicemesh/pmu-tools/:~/workspace/research/servicemesh/cl-wrk2/

declare -A POLICIES
policy_prefix=envoy_filters/policies
policy_files=$policy_prefix/*.yaml
for file in ${policy_files[@]}
do
	IFS='/-.' read -ra tag <<< $file
	POLICIES[${tag[3]}]=envoy-${tag[3]}.yaml
	#IFS='/' read -ra fname <<< $file
	#IFS='-.' read -ra tag <<< ${fname[2]}
	#POLICIES[ ${tag[1]} ]=${fname[2]}
done

DIR=syscall_trace
mkdir $DIR
for policy in "${!POLICIES[@]}"
do
	#start envoy
	outpath=$DIR/$policy
	envoy -c $policy_prefix/${POLICIES[$policy]} --concurrency 1 > /dev/null 2>&1 &
	sleep 1

	EPID=$(ps -C "envoy" -o pid= | tail -1)
	IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,comm | grep worker_0)
	WTID=${worker[0]}

	sudo strace -o trace_output -ff -p $EPID &

	curl -sl 0.0.0.0:10000 --header "Content-Type: application/json"
	curl -sl 0.0.0.0:10000 --header "Content-Type: application/json"

	sudo kill -9 $EPID
	sleep 1
	sudo mv trace_output.$WTID $outpath
	sudo rm trace_output.*
done
