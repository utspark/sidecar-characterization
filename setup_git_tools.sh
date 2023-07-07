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
