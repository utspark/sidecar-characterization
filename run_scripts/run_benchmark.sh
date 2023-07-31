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
WRK=wrk2
PROFILES=('default' 'demo' 'minimal')
while getopts 'cp:h' opt; do
	case "$opt" in
		c)
			echo "Using closed-loop load generator"
			WRK=wrk2-cornell
			;;
		p)
			arg="$OPTARG"
			echo "Setting Istio install profile as '${OPTARG}'"
			PROFILES=($arg)
			;;
		h)
			echo "Usage: $(basename $0) [OPTION]"
			echo "	     -c          Use closed-loop wrk2 load generator"
		       	echo "	     -p=PROFILE  Istio Installation Profile"
			exit 0
			;;
		*)
			echo "Usage: $(basename $0) [-c ] [-p <profile>]"
			echo "No options provided. Defaulting to open loop generator for all profiles of Istio"
			;;
	esac
done
shift "$(($OPTIND -1))"

export PATH=$PATH:$SCRIPTDIR/../../pmu-tools/:$SCRIPTDIR/../../$WRK/

function wait {
	all_ready=0
	while [[ $all_ready == 0 ]]
	do
		pend=$(kubectl get pods -o jsonpath='{.items[*].status.containerStatuses[*].ready}')
		stat=$(kubectl get pods -o jsonpath='{.items[*].status.containerStatuses[*].ready}')
		echo $stat
		if [[ $stat == *"false"* ]]; then
			sleep 10
		elif [[ -z $stat ]]; then
			sleep 30
		else
			all_ready=1
		fi
	done
}

function load_gen {
	echo "running wrk load test"	
	DIR=$1
	APP=$2
	MAX_RATE=$3
	STEP=$4 
	NUM=$(( $MAX_RATE/$STEP ))
	URL=$5
	mkdir -p $DIR/$APP
	
	for (( i=1; i<=$NUM; i++ ))
	do
		rate=$(( $i*$STEP ))
		#taskset -c 2,3 wrk --latency -t2 -c2 -d30s -s ./mixed-workload_type_1.lua -R$rate 'http://127.0.0.1:32080' > $DIR/${2}/latency_$rate
		taskset -c 2,4 wrk --latency -t2 -d120s -R$rate "http://127.0.0.1:32080$URL" > $DIR/$APP/latency_$rate
	done
}

APP_DIR=$SCRIPTDIR/../../benchmark_apps
#declare -A apps
declare -A paths
declare -A cmds
declare -A maxrate
declare -A step
declare -A istio_modes
apps=("bookinfo" "hotelreservation" "onlineboutique")
paths=(["bookinfo"]="istio-1.18.1/samples/bookinfo/platform/kube/bookinfo.yaml" ["hotelreservation"]="DeathStarBench/hotelReservation/kubernetes" ["onlineboutique"]="OnlineBoutique/release/kubernetes-manifests.yaml")
cmds=(["bookinfo"]="-f" ["hotelreservation"]="-Rf" ["onlineboutique"]="-f")
maxrate=(["bookinfo"]="300" ["hotelreservation"]="250" ["onlineboutique"]="40")
step=(["bookinfo"]="50" ["hotelreservation"]="50" ["onlineboutique"]="10")
url=(["bookinfo"]="/" ["hotelreservation"]="/hotels?inDate=2015-04-09&outDate=2015-04-10&lat=37.7749&lon=-122.4194" ["onlineboutique"]="/")
istio_modes=(["proxy"]="=enabled" ["noproxy"]="-")


dt=$(date '+%m%d')
for profile in "${PROFILES[@]}"
do
	setup_scripts/setup_istio.sh -d ~/ -p $profile
	for mode in "${!istio_modes[@]}"
	do
		kubectl label namespace default istio-injection${istio_modes[$mode]}
		for app in "${apps[@]}"
		do
			kubectl apply ${cmds[$app]} $APP_DIR/${paths[$app]}
			wait
			kubectl get po
			. ./run_scripts/run_latency.sh latency_$mode $app ${maxrate[$app]} ${step[$app]} ${url[$app]}
			kubectl delete ${cmds[$app]} $APP_DIR/${paths[$app]}
		done
	done
	echo "y" | setup_scripts/setup_istio.sh -d ~/ -c
	sleep 5
	output_dir=~/benchmark_latency$dt/$profile
	mkdir -p $output_dir
	mv latency* $output_dir
done

rm -rf ~/istio*

