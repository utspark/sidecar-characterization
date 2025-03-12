#!/bin/bash
#set -ex
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTDIR=$(dirname "$SCRIPT")

DIR=$1
# Process perf record
cd $DIR
recs=instructions*_record*
for rec in ${recs[@]}
do
	if [[ -f perf_report_$rec ]]; then
		continue
	fi
	echo $rec
	sudo perf report -i $rec -f > perf_report_$rec
done
cd -

sudo chown -R $(id -u):$(id -g) $DIR
