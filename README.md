# Setup
# Service mesh setup
Either setup using the Istio service with kubernetes or standalone Envoy.
To install Istio and kubernetes, run setup_istio.sh. *Doesn't work

# Envoy standalone setup
To install standalone Envoy, run setup_envoy_standalone.sh.
Docker may not be installed correctly at first, so rerun the apt-get install line to install docker.io and docker-compose-plugin.

Run the echo server using the docker compose file with the command `docker compose up -d` if the container is not runnning already.

# Profiling setup
Run the setup_perf.sh to install all components required to start profiling.

Turn off SMT with 
`sudo su -`

`echo off > /sys/devices/system/cpu/smt/control`

# Profiling
Use start_envoy.sh to setup envoy with x number of worker threads/cores and y% CPU utilization.
Ex. `./start_envoy.sh 2 50`

arg1 = number of core/worker threads

arg2 = CPU utilization per core

OR

If Envoy is installed correctly, run Envoy with `envoy -c envoy-demo.yaml --concurrency 1 > /dev/null 2>&1 &`.
Concurrency sets the number of worker threads for the Envoy process. Output is discarded and Envoy will run in the background.

The record_perf.sh will take in 3-4 args.
Ex. `./record_perf.sh stat no_filter 500` or `./record_perf.sh stat rate_limit mpki 1500`

arg1 = stat or record, the mode that perf should run

arg2 = policy applied to Envoy (no_filter, rate_limit, ip_tagging, both)

arg3 = OPTIONAL metric or event to run perf on (see script for options), if omitted, default is cycles and instructions

arg4 = rate of traffic to send to the echo server

Recording should be stopped after 10 seconds using Ctrl+C.
Results are outputted in perf_data directory.

# Tips for Using Standalone Envoy
If running multiple, edit the PROXY_ID field in the record_perf.sh script so perf knows the pid of the new Envoy proxy process. By default, it tracks the newest Envoy process.
Also if not using start_envoy.sh, make sure to set the correct number of core and CPU limits to the Envoy process before profiling or else results will be incorrect.
