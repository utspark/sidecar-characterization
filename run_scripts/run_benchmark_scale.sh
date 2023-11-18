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
PROFILES=('noproxy' 'default' 'demo' 'minimal')
APPS=("bookinfo" "hotelreservation" "onlineboutique")
while getopts 'a:cp:h' opt; do
	case "$opt" in
		c)
			echo "Using closed-loop load generator"
			WRK=wrk2-cornell
			;;
		a)
			arg="$OPTARG"
			echo "Running experiment for app '${OPTARG}' only"
			APPS=($arg)
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

function scale {
	factor=$1
	echo $factor
	#deployments=($(kubectl get deployments -o json | jq '.items[].metadata.name'))
	deployments=($(kubectl get deployments -o=custom-columns='NAME:.metadata.name' | tail -n +2))
	echo ${deployments[@]}
	for dep in "${deployments[@]}"
	do
		if [[ $dep == *"memcached"* ]]; then
			kubectl scale deployment $dep --replicas=1
		elif [[ $dep == *"mongo"* ]]; then
			kubectl scale deployment $dep --replicas=1
		else
			kubectl scale deployment $dep --replicas=$factor
		fi
	done
}

APP_DIR=$SCRIPTDIR/../../benchmark_apps
declare -A paths
declare -A cmds
declare -A maxrate
declare -A minrate
declare -A scaling
declare -A step
declare -A istio_modes
declare -A url
paths=(["bookinfo"]="istio-1.18.1/samples/bookinfo/platform/kube/bookinfo.yaml" ["hotelreservation"]="DeathStarBench/hotelReservation/kubernetes" ["onlineboutique"]="OnlineBoutique/release/kubernetes-manifests.yaml")
cmds=(["bookinfo"]="-f" ["hotelreservation"]="-Rf" ["onlineboutique"]="-f")
minrate=(["bookinfo"]="0" ["hotelreservation"]="0" ["onlineboutique"]="0")
maxrate=(["bookinfo"]="500" ["hotelreservation"]="800" ["onlineboutique"]="150")
scaling=(["bookinfo"]="5" ["hotelreservation"]="5" ["onlineboutique"]="5")
step=(["bookinfo"]="25" ["hotelreservation"]="40" ["onlineboutique"]="10")
url=(["bookinfo"]="/productpage" ["hotelreservation"]="/hotels?inDate=2015-04-09\&outDate=2015-04-10\&lat=37.7749\&lon=-122.4194" ["onlineboutique"]="/")
istio_modes=(["proxy"]="=enabled" ["noproxy"]="-")
#istio_modes=(["proxy"]="=enabled")
#istio_modes=(["noproxy"]="-")


scale_factor=$(kubectl get nodes | tail -n +2 | wc -l)
dt=$(date '+%m%d')
OUTPATH=~/benchmark_latency_${scale_factor}_${dt}_$SYSCALL
for profile in "${PROFILES[@]}"
do
#setup_scripts/setup_istio.sh -d ~/ -p demo
#for mode in "${!istio_modes[@]}"
#do
	if [[ $profile == 'noproxy' ]];then
		unset SYSCALL
		mode=$profile
	else
		setup_scripts/setup_istio.sh -d ~/ -p $profile
		mode="proxy"
	fi
	kubectl label namespace default istio-injection${istio_modes[$mode]}
	for app in "${APPS[@]}"
	do
		echo $app ${scaling[$app]}
		kubectl apply ${cmds[$app]} $APP_DIR/${paths[$app]}
		#scale ${scaling[$app]}
		scale $scale_factor
		wait
		kubectl get po
		. ./run_scripts/run_latency.sh latency_$mode $app ${maxrate[$app]} ${step[$app]} ${url[$app]} ${minrate[$app]} ${scale_factor}
		kubectl delete ${cmds[$app]} $APP_DIR/${paths[$app]}
	done
	
	if [[ $profile != 'noproxy' ]];then
		echo "y" | setup_scripts/setup_istio.sh -d ~/ -c
	fi
	sleep 5
	output_dir=$OUTPATH/$profile
	mkdir -p $output_dir
	mv latency* $output_dir
done
rm -rf ~/istio*

