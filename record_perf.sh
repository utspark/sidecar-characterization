#!/usr/bin/fish

set DIR './perf_data'
set SUB_DIR "$argv[2]"

# set CONT_PID 128654
# set CONT_PPID 128633
# set PROXY_ID 128609 # from old container using docker proxy
set PROXY_ID 700772

set SUFFIX "$argv[3]"
set EXT "data"

if string match -q -e 'st' "$argv[1]"
	set CMD 'stat'
	if [ "$SUFFIX" = 'icache' ]
		set FLAGS '-e' 'icache.hit,icache.ifetch_stall,icache.misses' '-I' '100'
		set SUFFIX '_icache'
	else if [ "$SUFFIX" = 'mpki' ]
		set FLAGS '-M' 'L1MPKI' '-I' '100' '-x' ','
		set SUFFIX '_mpki'
	else if [ "$SUFFIX" = 'branch' ]
		set FLAGS '-M' 'IpMispredict' '-I' '100' '-x' ','
		set SUFFIX '_branch'
	else if [ "$SUFFIX" = 'latency' ]
		set FLAGS '-M' 'Load_Miss_Real_Latency' '-I' '100'
		set SUFFIX '_latency'
	else
		set FLAGS '-e' 'cycles:u,cycles:k,instructions:u,instructions:k' '-I' '100'
		set SUFFIX ''
	end
	set EXT "csv"
else if string match -q -e 're' "$argv[1]"
	set CMD 'record'
	if [ "$SUFFIX" = 'icache' ]
		set FLAGS '-g' '-e' 'icache.misses' '-c' '10000'
		set SUFFIX '_icache'
	else if [ "$SUFFIX" = 'branch' ]
		set FLAGS '-g' '-e' 'branch-misses' '-c' '10000'
		set SUFFIX '_branch'
	else
		set FLAGS '-g' '-F' '10'
		set SUFFIX ''
	end
else if string match -q -e 'tr' "$argv[1]"
	set CMD 'trace'
	set FLAGS '-s' '--syscalls' '--call-graph' 'fp'
end

set DIR "$DIR/$CMD/$SUB_DIR"

# set PROCESS "$argv[2]"

# if [ "$PROCESS" = 'pid' ]
# 	set PID $CONT_PID
# else if [ "$PROCESS" = 'ppid' ]
# 	set PID $CONT_PPID
# else

set PID $PROXY_ID

set RATE "$argv[-1]"

wrk -t5 -d12 "-R$RATE" "http://10.111.70.135:80/param?query=demo" > "$DIR"/latency_stats_"$RATE$SUFFIX".txt &
echo "Starting requests to server with $RATE req/s"

set OUTPUT_FILE "$DIR"/"$RATE$SUFFIX"."$EXT"


echo "Running 'perf $CMD $FLAGS' on process $PID, outputting to $OUTPUT_FILE..."
echo "Press Ctrl+C to stop recording"
sudo perf $CMD $FLAGS -p $PID -o $OUTPUT_FILE
