#!/usr/bin/fish

# arg1 is envoy policy yaml to apply
# arg2 is num cpus to use
# arg3 is cpu usage limit percentage (optional)

# Auto updates the envoy pid to be profiled
# Manually set the PID if running with a service due to multiple envoy processses
set POLICY $argv[1]
set NUM_CPUS $argv[2]
set CPU_LIMIT $argv[3]

echo "Running envoy process with $POLICY applied with $NUM_CPUS worker threads"
envoy -c $POLICY --concurrency $NUM_CPUS > /dev/null 2>&1 &

set PROXY_ID (ps -C "envoy" -o pid= | tail -1)

if [ "$NUM_CPUS" = "1" ]
	set CPU_LIST "0"
else
	set CPU_LIST "1-$NUM_CPUS"
end

echo "Setting CPU list for process $PROXY_ID to $CPU_LIST"
taskset -pc $CPU_LIST $PROXY_ID

echo "Setting CPU usage for process $PROXY_ID to $CPU_LIMIT %"
cpulimit -p $PROXY_ID -l $CPU_LIMIT -b

