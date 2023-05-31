#!/bin/bash
# $1 = policy applied to envoy proxy
# $2 = number of cpus for the envoy proxy
# $3 = cpu limit percentage for envoy proxy

declare -A POLICIES
POLICIES=( [no_filter]=envoy-demo.yaml [rate_limit]=envoy-rate-limit.yaml
    [ip_tagging]=envoy-ip-tag.yaml #[both]=envoy-ip-rate.yaml 
    [header_inspect]=envoy-header-inspect.yaml [routing]=envoy-routing.yaml
    [logging]=envoy-logging.yaml [http_inspect]=envoy-http-inspect.yaml [rbac_list]=envoy-rbac-reject-list.yaml
    [rbac_one]=envoy-rbac-reject-one.yaml [ip_filter]=envoy-l4-ip-filter.yaml
    [tls]=envoy-tls.yaml [lua]=envoy-lua.yaml)
STATS=( none ipmispredict branch icache mpki llc context )
RECORDS=( none )
REQ_RATES=( 500 )
BODY_LEN=( 100 1000 4000 8000 32000 34000 64000 )

policy=$1
YAML="${POLICIES[$policy]}"

mkdir -p perf_data/l7/stat/$policy perf_data/l4/stat/$policy

./start_envoy.sh $YAML $2 $3 &
sleep 5
PID=$(ps -C "envoy" -o pid= | tail -1)
for stat in "${STATS[@]}"
do
    for req_rate in "${REQ_RATES[@]}"
    do
        if [ "$policy" = "routing" ] || [ "$policy" = "header_inspect" ]; then
            req_rate=$((req_rate / 2))
        fi

        # Allow wrk to finish recording latency stats
        # timeout 13 ./record_perf.sh record $policy $stat $req_rate
        timeout 13 ./record_perf.sh stat $policy $stat $req_rate
        sleep 2

        for body_len in "${BODY_LEN[@]}"
        do
            timeout 13 ./record_perf.sh stat $policy $stat $req_rate body $body_len
            sleep 2
        done
    done
done

sudo kill $PID

echo Done running collecting all stats for $policy
