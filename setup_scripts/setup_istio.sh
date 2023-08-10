#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
DIR=$SCRIPTDIR/../../benchmark_apps/
PROFILE=demo
CLEAN=0
while getopts 'cd:p:h' opt; do
	case "$opt" in
		d)
			arg="$OPTARG"
			echo "Setting Istio download path to '${OPTARG}'"
			DIR=$arg
			;;
		p)
			arg="$OPTARG"
			echo "Setting Istio install profile as '${OPTARG}'"
			PROFILE=$arg
			;;
		c)
			echo "Clean current Istio profile"
			CLEAN=1
			;;
		h)
			echo "Usage: $(basename $0) [OPTION]"
			echo "	     -d=DIR      Path to look for Istio repository (or install if absent)"
		       	echo "	     -p=PROFILE  Istio Installation Profile"
			exit 0
			;;
		*)
			echo "Usage: $(basename $0) [-d <Install dir>] [-p <profile>]"
			echo "No options provided. Defaulting to '$DIR' and '$PROFILE' for Istio"
			;;
	esac
done
shift "$(($OPTIND -1))"

#Istio Version
ISTIO_VERSION="$(curl -sL https://github.com/istio/istio/releases | \
	grep -o 'releases/[0-9]*.[0-9]*.[0-9]*/' | sort -V | \
	tail -1 | awk -F'/' '{ print $2}')"
ISTIO_VERSION="${ISTIO_VERSION##*/}"
echo $ISTIO_VERSION

#Install/Uninstall Istio
cd $DIR
[ ! -d istio-$ISTIO_VERSION ] && curl -L https://istio.io/downloadIstio | sh -
cd istio-$ISTIO_VERSION
if [[ $CLEAN == 1 ]]; then
	kubectl delete -f $SCRIPTDIR/disable-tls.yaml
	bin/istioctl uninstall --purge
else
	bin/istioctl install --set profile=$PROFILE -y
	echo "To enable proxy injection: kubectl label namespace default istio-injection=enabled"
	kubectl apply -f $SCRIPTDIR/disable-tls.yaml
fi
cd -



