# SCoPE
This toolkit allows an operator to perform distributed metrics collection and analysis.
We utilize this tool to monitor sidecar processes in a distributed cloud microservice setup and characterize the performance of sidecars under different operating conditions.

The tool collects both system level and hardware metrics that are configurable. This repository also contains a set of python notebook scripts that can be use to visualize collected metrics for analysis. Please cite our paper if you find this tool useful and use it in your work.

# Setup
## Configure nodes
We can use our data collection framework on a single node or multi-node clusters. We require all nodes of a cluster to have a shared NFS drive which houses this toolkit. This is not necessary, but is required by this toolkit to synchronize and collect data from different clusters. All benchmarks and microbenchmarks can be run on single node cluster.
Each node needs to be configured with required packages and tools by running `setup_scripts/setup_node.sh`.\\

Kubernetes can be deployed by running `setup_scripts/setup_kubernetes.sh master` on master node or in single node clusters. For multi-node clusters, all worker nodes can be setup by running `setup_scripts/setup_kubernetes.sh`.

## Service mesh setup
We can use a complete service mesh setup or run standalone sidecars. Our paper uses complete service mesh setups to run complete benchmark applications while we utilize standalone envoy sidecars for the majority of characterization results to reduce system noise and result variability.

### Setup service mesh
We use Istio service mesh setups. Istio provides a few default configurations: `demo`, `default`, `minimal` etc.
We can configure the cluster to use Istio by running `setup_scripts/setup_istio.sh -p <profile> -d <optional: dir>`.

To uninstall only the istio components you can simply run `setup_scripts/setup_istio.sh -c`.

### Envoy standalone setup
To run standalone Envoy sidecars, you can simply run the installed `envoy` binary with configured options. Learn more about Envoy options by running `envoy --help`.
Some of the Envoy configurations used in our microbenchmarks (e.g. SQL) are not available in the default Envoy distributions and needs to built or pulled separately.

The official Envoy repository describes steps to build such extensions. We work around the problem by pulling Envoy-contrib extension pre-built package from existing official container releases [envoy-contrib-dev](https://hub.docker.com/r/envoyproxy/envoy-contrib-dev). 

## Dependency repositories
Our toolkit relies on a few other open-source projects like [wrk2](https://github.com/giltene/wrk2.git) and [pmu-tools](https://github.com/andikleen/pmu-tools.git) for load generation and collecting hardware metrics collections.\\
Separately, we also use a few opensource benchmark applications in our profiling.

All these repositories can be pulled and appropriately setup by running `setup_scripts/setup_git_tools.sh`.

# Profiling setup

## Profiling benchmark applications

### Latency throughput plots
We can run data collection for running benchmark applications with and without service meshes by simply running
`run_scripts/run_benchmark.sh`

For multinode clusters, we need to run `run_scripts/run_benchmark_scale.sh`.

### Cycle breakdown
To understand the cycle level overheads per sidecar process in an application, we run `run_scripts/run_perf_cycles.sh` on all node-clusters.

This utilizes shared files in the NFS shared folder to synchronize between data-collection across nodes.

## Profiling microbenchmark policies

Microbenchmarking experiments evaluate the performance breakdown of network requests over a diverse set of Envoy filters. The list of filters are defined in `envoy_filters/policies/` and can be expanded based on an operators' needs.

There are the following scripts that collects different metrics for these policies. All scripts are available under `run_scripts` folder.
| Script Name | Functionality |
|-------------|---------------|
| run_perf    | Collects time series data for set of perf metrics |
| run_perf_size | Collects perf metrics for changing payload sizes |
| run_perf_toplev | Collects toplev metrics for different CPU loads |
| run_perf_sql | Same as run_perf but for SQL backend |

# Citation


