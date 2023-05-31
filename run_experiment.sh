#!/bin/bash
# $1 = number of cpus for the envoy proxy
# $2 = cpu limit percentage for envoy proxy

declare -A POLICIES
POLICIES=( [no_filter]=envoy-demo.yaml [rate_limit]=envoy-rate-limit.yaml
    [ip_tagging]=envoy-ip-tag.yaml #[both]=envoy-ip-rate.yaml 
    [header_inspect]=envoy-header-inspect.yaml [routing]=envoy-routing.yaml
    [logging]=envoy-logging.yaml [http_inspect]=envoy-http-inspect.yaml [rbac_list]=envoy-rbac-reject-list.yaml
    [rbac_one]=envoy-rbac-reject-one.yaml [ip_filter]=envoy-l4-ip-filter.yaml
    [tls]=envoy-tls.yaml [lua]=envoy-lua.yaml)
STATS=( none mpki branch icache llc context ) #ipmispredict
REQ_RATES=( 3000 6000 9000 )

for policy in "${!POLICIES[@]}"
do

    # only one of the folders will be populated, too lazy to rewrite logic for this
    mkdir -p perf_data/l7/stat/$policy perf_data/l4/stat/$policy

    ./start_envoy.sh ${POLICIES[$policy]} $1 $2 &

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
            timeout 13 ./record_perf.sh stat $policy $stat $req_rate
            sleep 2
        done
    done

    sudo kill $PID
    sleep 5

    echo Done running collecting all stats for $policy
done
