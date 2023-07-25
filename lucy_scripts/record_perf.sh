#!/usr/bin/fish

# arg1 is stat or record
# arg2 is the policy applied
# arg3 is the stat to be recorded (optional, default is instructions & cycles)
# arg4 is request rate to envoy

# 0.0.0.0:10000 is the default ip and port for standalone envoy
set IP '0.0.0.0'
set PORT '10000'

set -l L7_POLICIES no_filter rate_limit ip_tagging both header_inspect routing logging
set -l L4_POLICIES http_inspect rbac_list rbac_one ip_filter tls

if contains "$argv[2]" $L7_POLICIES
	set POLICY_TYPE l7
else if contains "$argv[2]" $L4_POLICIES
	set POLICY_TYPE l4
else
	echo "Policy not found"
	set POLICY_TYPE unknown
end


# Auto updates the envoy pid to be profiled
# Manually set the PID if running with a service mash due to multiple envoy processes
set PROXY_ID (ps -C "envoy" -o pid= | tail -1)
# set PROXY_ID 2425181

set SUFFIX "_$argv[3]"
set EXT "data"

set STAT_FLAGS '-I' '100' '--interval-count' '110' '-x' ','

if [ "$argv[1]" = 'stat' ]
	set CMD 'stat'
	if string match -q -e 'icache' "$SUFFIX"
		set FLAGS '-e' 'icache.hit,icache.ifetch_stall,icache.misses'
	else if string match -q -e 'mpki' "$SUFFIX"
		set FLAGS '-M' 'L1MPKI'
	else if string match -q -e 'ipmispredict' "$SUFFIX"
		set FLAGS '-M' 'IpMispredict'
	else if string match -q -e 'branch' "$SUFFIX"
		set FLAGS '-e' 'branch-instructions,branch-misses'
		set STAT_FLAGS '-I' '10' '--interval-count' '1100' '-x' ','
	else if string match -q -e 'llc' "$SUFFIX"					
		set FLAGS '-e' 'offcore_response.all_requests.llc_hit.any_response,offcore_response.all_requests.llc_miss.any_response'		# check if machine support these events via 'perf list llc'
	else if string match -q -e 'context' "$SUFFIX"
		set FLAGS '-e' 'context-switches'
	# else if string match -q -e 'load' "$SUFFIX"
	# 	set FLAGS '-M' 'IpL' '-I' '100' '-x' ','
	# else if string match -q -e 'store' "$SUFFIX"
	# 	set FLAGS '-M' 'IpS' '-I' '100' '-x' ','
	# else if string match -q -e 'fill' "$SUFFIX"
	 	# set FLAGS '-M' 'L1D_Cache_Fill_BW' '-I' '100' '-x' ','
	# else if [ "$SUFFIX" = 'latency' ] #unused since can't be recorded
	# 	set FLAGS '-M' 'Load_Miss_Real_Latency' '-I' '100'
	else
		set FLAGS '-e' 'cycles:u,cycles:k,instructions:u,instructions:k'
		set SUFFIX ''
	end
	set FLAGS $FLAGS $STAT_FLAGS
	set EXT "csv"
else if [ "$argv[1]" = 'record' ]
	set CMD 'record'
	if string match -q -e 'icache' "$SUFFIX"
		set FLAGS '-g' '-e' 'icache.misses' '-c' '10000'
	else if string match -q -e 'branch' "$SUFFIX"
		set FLAGS '-g' '-e' 'branch-misses' '-c' '10000'
	else
		set FLAGS '-g' '-F' '10'
		set SUFFIX ''
	end
else if [ "$argv[1]" = 'trace' ]
	set CMD 'trace'
	set FLAGS '-s' '--syscalls' '--call-graph' 'fp'
end

set SUB_DIR "$argv[2]"
set DIR "perf_data/$POLICY_TYPE/$CMD/$argv[2]"
set PID $PROXY_ID

set RATE "$argv[-1]"
set OUTPUT_FILE "$DIR"/"$RATE$SUFFIX"."$EXT"

echo "Starting requests to server with $RATE req/s"
if [ "$argv[2]" = 'routing'  ]
	wrk -t1 -c1 -d12 "-R$RATE" "http://$IP:$PORT/route2" > "$DIR"/latency_stats_"$RATE$SUFFIX"_route2.txt &
else if [ "$argv[2]" = 'header_inspect' ]
	wrk -t1 -c1 -d12 "-R$RATE" -s fault_header.lua "http://$IP:$PORT" > "$DIR"/latency_stats_"$RATE$SUFFIX"_header.txt &
end

wrk -t1 -c1 -d12 "-R$RATE" "http://$IP:$PORT" > "$DIR"/latency_stats_"$RATE$SUFFIX".txt &

# other wrk commands to send different requests to the echo server
# below is for fault injection (envoy-header-inspect)
# wrk -t1 -c1 -d12 "-R$RATE" -s header.lua "http://$IP:$PORT" > "$DIR"/latency_stats_"$RATE$SUFFIX_header".txt &

# below is for routing (envoy-routing)
# wrk -t1 -c1 -d12 "-R$RATE" "http://$IP:$PORT/route2" > "$DIR"/latency_stats_"$RATE$SUFFIX_header".txt &

# headers for echo server
# wrk -t1 -c1 -d12 "-R$RATE" "http://$IP:$PORT/?echo_header=wrk:0" > "$DIR"/latency_stats_"$RATE$SUFFIX_0".txt &
# wrk -t1 -c1 -d12 "-R$RATE" "http://$IP:$PORT/?echo_header=wrk:1" > "$DIR"/latency_stats_"$RATE$SUFFIX_1".txt &

echo "Running 'perf $CMD $FLAGS' on process $PID, outputting to $OUTPUT_FILE..."
echo "Press Ctrl+C to stop recording"
sudo perf $CMD $FLAGS -p $PID -o $OUTPUT_FILE
