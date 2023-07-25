#!/bin/bash

#################################################################
# run wrk load generator for running microservices		#
# cmd-line args: ./run_latency <dir> <app> <max-rate> <step>    #
#################################################################

#set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")

export PATH=$PATH:$SCRIPTDIR/../../pmu-tools/:$SCRIPTDIR/../../wrk2/

function wait {
	all_ready=0
	while [[ $all_ready == 0 ]]
	do
		stat=$(kubectl get pods -o jsonpath='{.items[*].status.containerStatuses[*].ready}')
		if [[ $stat == *"false"* ]]; then
			sleep 10
		else
			all_ready=1
		fi
	done
}

function load_gen {
	
	DIR=$1
	APP=$2
	MAX_RATE=$3
	STEP=$4 
	NUM=$(( $MAX_RATE/$STEP ))
	mkdir -p $DIR/$APP
	
	for (( i=1; i<=$NUM; i++ ))
	do
		rate=$(( $i*$STEP ))
		#taskset -c 2,3 wrk --latency -t2 -c2 -d30s -s ./mixed-workload_type_1.lua -R$rate 'http://127.0.0.1:32080' > $DIR/${2}/latency_$rate
		taskset -c 2,4 wrk --latency -t2 -d30s -R$rate 'http://127.0.0.1:32080' > $DIR/$APP/latency_$rate
	done
}

APP_DIR=$SCRIPTDIR/../benchmark_apps
#declare -A apps
declare -A paths
declare -A cmds
declare -A maxrate
declare -A step
declare -A istio_modes
apps=("bookinfo" "hotelreservation" "onlineboutique")
paths=(["bookinfo"]="istio-1.18.1/samples/bookinfo/platform/kube/bookinfo.yaml" ["hotelreservation"]="DeathStarBench/hotelReservation/kubernetes" ["onlineboutique"]="OnlineBoutique/release/kubernetes-manifests.yaml")
cmds=(["bookinfo"]="-f" ["hotelreservation"]="-Rf" ["onlineboutique"]="-f")
maxrate=(["bookinfo"]="300" ["hotelreservation"]="10" ["onlineboutique"]="20")
step=(["bookinfo"]="50" ["hotelreservation"]="1" ["onlineboutique"]="2")
istio_modes=(["proxy"]="=enabled" ["noproxy"]="-")


for app in "${apps[@]}"
do
	for mode in "${!istio_modes[@]}"
	do
		kubectl label namespace default istio-injection${istio_modes[$mode]}
		kubectl apply ${cmds[$app]} $APP_DIR/${paths[$app]}
		wait
		kubectl get po
		load_gen latency_$mode $app $maxrate[$app] $step[$app]
		kubectl delete ${cmds[$app]} $APP_DIR/${paths[$app]}
	done
done
