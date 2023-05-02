#!/bin/bash
# $1 = policy applied to envoy proxy
# $2 = number of cpus for the envoy proxy
# $3 = cpu limit percentage for envoy proxy

declare -A POLICIES
POLICIES=( [no_filter]=envoy-demo.yaml [rate_limit]=envoy-rate-limit.yaml
    [ip_tagging]=envoy-ip-tag.yaml #[both]=envoy-ip-rate.yaml 
    [header_inspect]=envoy-header-inspect.yaml [routing]=envoy-routing.yaml
    [logging]=envoy-logging.yaml [http_inspect]=envoy-http-inspect.yaml [rbac_list]=envoy-rbac-reject-list.yaml
    [rbac_one]=envoy-rbac-reject-one.yaml [ip_filter]=envoy-l4-ip-filter.yaml)
STATS=( '' mpki ipmispredict branch icache llc context )
REQ_RATES=( 3000 6000 9000 )

policy=$1
YAML="${POLICIES[$policy]}"

# mkdir -p perf_data/l7/stat/no_filter perf_data/l7/stat/rate_limit perf_data/l7/stat/ip_tagging perf_data/l7/stat/routing perf_data/l7/stat/header_inspect #perf_data/stat/both #perf_data/stat/admit_ctrl

# Start envoy with no filter config
# ./setup_envoy_alone.sh
# ./setup_perf.sh

#for policy in "${!POLICIES[@]}"
#do
    # echo $key ${POLICIES[$key]}
# only one of the folders will be populated, too lazy to rewrite logic for this
    mkdir -p perf_data/l7/stat/$policy perf_data/l4/stat/$policy

#    ./start_envoy.sh ${POLICIES[$policy]} $1 $2 &
    ./start_envoy.sh $YAML $2 $3 &
    sleep 5
    PID=$(ps -C "envoy" -o pid= | tail -1)
echo $PID
    for stat in "${STATS[@]}"
    do
        for req_rate in "${REQ_RATES[@]}"
        do
            if [ "$policy" = "routing" ] || [ "$policy" = "header_inspect" ]; then
		    req_rate=$((req_rate / 2))
	    fi
	    #echo $req_rate
	    #echo $1 $stat $req_rate
            # Allow wrk to finish recording latency stats
            timeout 13 ./record_perf.sh stat $policy $stat $req_rate
            sleep 2
        done
    done

    sudo kill $PID
    sleep 5

    echo Done running collecting all stats for $policy
#done

# # Start envoy with RBAC network filter config
# sudo ./start_envoy.sh envoy-l4-ip-filter.yaml 1 100 &
# PID2=(ps -C "envoy" -o pid=)
# sleep 5

# # Test RBAC with request rates of 500, 1000
# sudo timeout 10 ./perf-l4.sh stat rbac 500
# sudo timeout 10 ./perf-l4.sh stat rbac 1000
# sudo kill $PID2
