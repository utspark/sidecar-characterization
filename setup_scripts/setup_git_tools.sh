#!/bin/bash

# Install wrk2
git clone https://github.com/giltene/wrk2.git
cd wrk2
make
sudo cp wrk /usr/local/bin
cd ..

# Install pmu-tools
git clone git@github.com:andikleen/pmu-tools.git
cd pmu-tools
sudo cp toplev /usr/local/bin
cd ..

# Get benchmark applications
mkdir -p ../../benchmark_apps/
cd ../../benchmark_apps
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git OnlineBoutique
git clone https://github.com/delimitrou/DeathStarBench.git
curl -L https://istio.io/downloadIstio | sh -
