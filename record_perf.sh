#!/usr/bin/fish

# arg1 is stat or record
# arg2 is the policy applied
# arg3 is the stat to be recorded

# 0.0.0.0:10000 is the default container ip and port for standalone envoy
set IP '0.0.0.0'
set PORT '10000'

mkdir -p perf_data/stat/no_filter perf_data/stat/rate_limit perf_data/stat/ip_tagging perf_data/stat/both perf_data/stat/admit_ctrl
mkdir -p perf_data/record/no_filter perf_data/record/rate_limit perf_data/record/ip_tagging perf_data/record/both perf_data/record/admit_ctrl

# Auto updates the envoy pid to be profiled
# Manually set the PID if running with a service due to multiple envoy processses
echo 'Make sure you taskset and limit cpu time for the envoy process'
set PROXY_ID (ps -C "envoy" -o pid= | string trim)

set SUFFIX "_$argv[3]"
set EXT "data"

if [ "$argv[1]" = 'stat' ]
	set CMD 'stat'
	if string match -q -e 'icache' "$SUFFIX"
		set FLAGS '-e' 'icache.hit,icache.ifetch_stall,icache.misses' '-I' '100' '-x' ','
	else if string match -q -e 'mpki' "$SUFFIX"
		set FLAGS '-M' 'L1MPKI' '-I' '100' '-x' ','
	else if string match -q -e 'ipmispredict' "$SUFFIX"
		set FLAGS '-M' 'IpMispredict' '-I' '100' '-x' ','
	else if string match -q -e 'branch' "$SUFFIX"
		set FLAGS '-e' 'branch-misses' '-I' '100' '-x' ','
	# else if string match -q -e 'load' "$SUFFIX"
	# 	set FLAGS '-M' 'IpL' '-I' '100' '-x' ','
	# else if string match -q -e 'store' "$SUFFIX"
	# 	set FLAGS '-M' 'IpS' '-I' '100' '-x' ','
	else if string match -q -e 'fill' "$SUFFIX"
	 	set FLAGS '-M' 'L1D_Cache_Fill_BW' '-I' '100' '-x' ','
	# else if [ "$SUFFIX" = 'latency' ] #unused since can't be recorded
	# 	set FLAGS '-M' 'Load_Miss_Real_Latency' '-I' '100'
	else
		set FLAGS '-e' 'cycles:u,cycles:k,instructions:u,instructions:k' '-I' '100' '-x' ','
		set SUFFIX ''
	end
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
set DIR "perf_data/$CMD/$argv[2]"
set PID $PROXY_ID

set RATE "$argv[-1]"

wrk -t5 -d12 "-R$RATE" "http://$IP:$PORT/param?query=demo" > "$DIR"/latency_stats_"$RATE$SUFFIX".txt &
echo "Starting requests to server with $RATE req/s"

set OUTPUT_FILE "$DIR"/"$RATE$SUFFIX"."$EXT"


echo "Running 'perf $CMD $FLAGS' on process $PID, outputting to $OUTPUT_FILE..."
echo "Press Ctrl+C to stop recording"
sudo perf $CMD $FLAGS -p $PID -o $OUTPUT_FILE
