#!/bin/bash

#Istio Version

ISTIO_VERSION="$(curl -sL https://github.com/istio/istio/releases | \
	grep -o 'releases/[0-9]*.[0-9]*.[0-9]*/' | sort -V | \
	tail -1 | awk -F'/' '{ print $2}')"
ISTIO_VERSION="${ISTIO_VERSION##*/}"
print $ISTIO_VERSION

#Install Istio
cd ../../benchmark_apps/
[ ! -d istio-$ISTIO_VERSION ] && curl -L https://istio.io/downloadIstio | sh -
cd istio-$ISTIO_VERSION
bin/istioctl install --set profile=demo -y
cd -

echo "To enable proxy injection: kubectl label namespace default istio-injection=enabled"


