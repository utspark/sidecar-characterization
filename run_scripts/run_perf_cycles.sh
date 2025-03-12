#!/bin/bash

#set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")
WRK=wrk2
PROFILES=('noproxy' 'default')
APPS=("bookinfo" "hotelreservation" "onlineboutique")
INSTALL=1
MASTER_NODE="node-0"
while getopts 'a:cp:m:lh' opt; do
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
		m)
			arg="$OPTARG"
			echo "Setting master node to '${OPTARG}'"
			MASTER_NODE=($arg)
			;;
		l)
			echo "Only running load test"
			INSTALL=0
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

declare -A stat
stat[1]=instructions
stat[2]=instructions,cycles

HOST_PORT="127.0.0.1:32080"

nodes=''
function trigger {
	trigger_file=$1
	#set -x
	for node in ${nodes[@]}
	do
		ssh -o StrictHostKeyChecking=no psahu@$node "touch $SCRIPTDIR/$trigger_file" &
		echo $node
	done
	#set +x
}

function perf {
	PIDS=$1
	DIR=$2
	URL=$3
	rate=$4
	nodename=$5

	echo $5
	set -x
	for i in {1..5}
	do
		if [[ $nodename == $MASTER_NODE ]]; then
			#ssh -o StrictHostKeyChecking=no psahu@node-1$extension "touch $SCRIPTDIR/thread_stat.txt"
			trigger thread_stat.txt
		else
			inotifywait -e create,moved_to,attrib "$SCRIPTDIR/thread_stat.txt"
		fi
		if [[ $PIDS == 0 ]]; then
			sleep 100
		else
			sudo perf stat -I 1000 -e cycles:u,cycles:k,instructions:u,instructions:k -p $PIDS -o $DIR/cycle_inst_stat_$i -- sleep 100 &
			#sudo perf stat -I 1000 -e cycles:u,cycles:k,instructions:u,instructions:k -p $PIDS --per-thread -o $DIR/cycle_inst_stat_$i -- sleep 100 &
		fi
		#taskset -c 2,3 wrk --latency -c2 -t1 -d120s -R20 "http://$HOST_PORT/productpage" > latency
		if [[ $nodename == $MASTER_NODE ]]; then
			sleep 1
			taskset -c 2,4 wrk --latency -c2 -t1 -d120s -R$rate "http://${HOST_PORT}$URL" > $DIR/latency_${rate}_$i
		fi
		sleep 2
	done

	for i in {1..2}
	do
		if [[ $nodename == $MASTER_NODE ]]; then
			#ssh -o StrictHostKeyChecking=no psahu@node-1$extension "touch $SCRIPTDIR/all_stat.txt"
			trigger all_stat.txt
		else
			inotifywait -e create,moved_to,attrib "$SCRIPTDIR/all_stat.txt"
		fi
		sudo perf stat -I 1000 -e cycles:u,cycles:k,instructions:u,instructions:k -a -o $DIR/cycle_inst_stat_system_$i -- sleep 100 &
		if [[ $nodename == $MASTER_NODE ]]; then
			sleep 1
			taskset -c 2,4 wrk --latency -c2 -t1 -d120s -R$rate "http://${HOST_PORT}$URL" > $DIR/latency_system_${rate}_$i
		fi
		sleep 2
	done
	set +x
}

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

APP_DIR=$SCRIPTDIR/../../benchmark_apps
declare -A paths
declare -A cmds
declare -A maxrate
declare -A step
declare -A url
declare -A istio_modes
paths=(["bookinfo"]="istio-1.18.1/samples/bookinfo/platform/kube/bookinfo-4.yaml" ["hotelreservation"]="DeathStarBench/hotelReservation/kubernetes" ["onlineboutique"]="OnlineBoutique/release/kubernetes-manifests.yaml")
cmds=(["bookinfo"]="-f" ["hotelreservation"]="-Rf" ["onlineboutique"]="-f")
rate=(["bookinfo"]="20" ["hotelreservation"]="20" ["onlineboutique"]="20")
url=(["bookinfo"]="/productpage" ["hotelreservation"]="/hotels?inDate=2015-04-09\&outDate=2015-04-10\&lat=37.7749\&lon=-122.4194" ["onlineboutique"]="/")
istio_modes=(["proxy"]="=enabled" ["noproxy"]="-")
#istio_modes=(["proxy"]="=enabled")

dt=$(date '+%m%d')
IFS='.' read -ra HOST <<< $(hostname)
nodename=${HOST[0]}
if [[ $nodename == $MASTER_NODE ]]; then
	nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.labels.kubernetes\.io\/hostname}')
	nodes=( "${nodes[@]/$(hostname)}" )
fi
#extension=''
#for ((i=1; i<${#HOST[@]}; i++)); do
#	extension=$extension.${HOST[$i]}
#done
#echo $extension
OUTPATH=~/benchmark_cycles${dt}_$nodename
for profile in "${PROFILES[@]}"
do
	output_dir=$OUTPATH/$profile
	mkdir -p $output_dir
	if [[ $profile == 'noproxy' ]]; then
		mode=$profile
	else
		if [[ $nodename == $MASTER_NODE && $INSTALL == 1 ]]; then
			setup_scripts/setup_istio.sh -d ~/ -p $profile
		fi
		mode='proxy'
	fi
	if [[ $nodename == $MASTER_NODE ]]; then
		kubectl label namespace default istio-injection${istio_modes[$mode]}
	fi
	for app in "${APPS[@]}"
	do
		if [[ $nodename == $MASTER_NODE && $INSTALL == 1 ]]; then
			kubectl apply ${cmds[$app]} $APP_DIR/${paths[$app]}
			wait
			kubectl get po
			#ssh -o StrictHostKeyChecking=no psahu@node-1$extension touch $SCRIPTDIR/ready.txt
			trigger ready.txt
			sleep 5
		else
			inotifywait -e create,moved_to,attrib "$SCRIPTDIR/ready.txt"
		fi

		PIDS=$($SCRIPTDIR/get-details.py -t app)
		if [[ $PIDS == '' ]]; then
			PIDS=0
		fi
		mkdir -p $output_dir/$app
		$SCRIPTDIR/get-details.py -d pickle -p $output_dir/$app 
		#for i in {1..5}
		#do
		perf $PIDS $output_dir/$app ${url[$app]} ${rate[$app]} $nodename
		#done
		
		if [[ $nodename == $MASTER_NODE && $INSTALL == 1 ]]; then
			kubectl delete ${cmds[$app]} $APP_DIR/${paths[$app]}
		fi
	done
	if [[ $nodename == $MASTER_NODE && $INSTALL == 1 ]]; then
		echo "y" | setup_scripts/setup_istio.sh -d ~/ -c
	fi
	sleep 5
done
