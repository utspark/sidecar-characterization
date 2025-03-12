# Setup
## Service mesh setup
Either setup using the Istio service with kubernetes or standalone Envoy.
To install Istio and kubernetes, run setup_istio.sh. *Doesn't work

## Envoy standalone setup
To install standalone Envoy, run setup_envoy_standalone.sh.
Docker may not be installed correctly at first, so rerun the apt-get install line to install docker.io and docker-compose-plugin.

Run the echo server using the docker compose file with the command `docker compose up -d` if the container is not runnning already.

## Profiling setup
Run the setup_perf.sh to install all components required to start profiling.

Turn off SMT with 
`sudo su -`

`echo off > /sys/devices/system/cpu/smt/control`

# Profiling
Use run_experiment.sh or single_experiment.sh to automate the datacollecting process. These two scripts start the envoy process with x number of worker threads/cores and y% CPU utilization. run_experiment.sh collects perf stats for all policies, and single_experiment.sh collects perf stats for a single policy.

run_experiment.sh takes in the following parameters:

arg1 = number of core/worker threads

arg2 = CPU utilization per core


single_experiment.sh takes in the following parameters:

arg1 = policy name

arg2 = number of core/worker threads

arg3 = CPU utilization per core


start_envoy.sh takes in 2 args to setup an envoy process with x cores and y% utilization per core.

arg1 = number of cores/worker threads

arg2 = CPU utilization per core


The record_perf.sh will take in 4 or 6 args.
Ex. `./record_perf.sh stat no_filter none 500` or `./record_perf.sh stat rate_limit lua 100 body 1000`

arg1 = stat or record, the mode that perf should run

arg2 = policy applied to Envoy (no_filter, rate_limit, ip_tagging, both)

arg3 = metric or event to run perf on (see script for options), default is cycles and instructions

arg4 = rate of traffic to send to the echo server

arg5 = OPTIONAL if "body", use the following parameter to load the lua file containing the request body and headers, only used for the lua filter

arg6 = REQUIRED if arg5 is "body", the length of the request body

Results are outputted in perf_data directory.

# Tips for Using Standalone Envoy
If running multiple envoy processes, edit the PROXY_ID field in the record_perf.sh script so perf knows the pid of the correct Envoy proxy process. By default, it tracks the newest Envoy process.

Also if not using the experiment.sh scripts or start_envoy.sh, make sure to set the correct number of core and CPU limits to the Envoy process before profiling or else results will be incorrect.
