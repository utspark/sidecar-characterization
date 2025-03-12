#!/bin/bash

#################################################################
# run wrk load generator for running microservices		#
# cmd-line args: ./run_latency <dir> <app> <max-rate> <step>    #
#################################################################

function scale {
	factor=$1
	echo $factor
	#deployments=($(kubectl get deployments -o json | jq '.items[].metadata.name'))
	deployments=($(kubectl get deployments -o=custom-columns='NAME:.metadata.name' | tail -n +2))
	echo ${deployments[@]}
	for dep in "${deployments[@]}"
	do
		if [[ $dep == *"memcached"* ]]; then
			kubectl scale deployment $dep --replicas=2
		elif [[ $dep == *"mongo"* ]]; then
			kubectl scale deployment $dep --replicas=2
		else
			kubectl scale deployment $dep --replicas=$factor
		fi
	done
}

if  [[ -z $1 ]]; then
	scale_factor=$(kubectl get nodes | tail -n +2 | wc -l)
else
	scale_factor=$1
fi
scale $scale_factor

