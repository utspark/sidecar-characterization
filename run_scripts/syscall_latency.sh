#!/bin/bash
#set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")

export PATH=$PATH:$SCRIPTDIR/../../pmu-tools/:$SCRIPTDIR/../../wrk2/

#Start syscall trace
function trace_syscall {
EPID=$(ps -C "envoy" -o pid= )
pid_s=''
for epid in ${EPID[@]}
do
	pid_s=${pid_s},$epid
done
pid_s="${pid_s:1}"
echo $pid_s
#sudo strace -T -tt -e trace=writev,readv -o trace_output -ff -p $pid_s &
#sleep 1
#SPID=$!
#echo $SPID
}

#End syscall trace
function get_workers {
	local -n WTID=$1
	EPID=$(ps -C "envoy" -o pid= )
	for epid in ${EPID[@]}
	do
		IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,pid,comm | grep $epid | grep worker_0)
		WTID+=( ${worker[0]} )
		IFS=' ' read -ra worker <<< $(ps -T -C envoy -o spid,pid,comm | grep $epid | grep worker_1)
		WTID+=( ${worker[0]} )
	done
	#echo "${WTID[@]}"
}

function save_trace {
	outpath=$1
	path_ext=$2
	WTID=("${@:3}")
	echo "${WTID[@]}"
	for tid in ${WTID[@]}
	do
		sudo mv trace_output.$tid $outpath/trace_output.${tid}_${path_ext}
	done
	sudo rm trace_output.*
}

