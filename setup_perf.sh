# Install perf tools
sudo apt install linux-tools-common linux-tools-generic linux-tools-$(uname -r)

# Install wrk2
git clone https://github.com/giltene/wrk2.git
cd wrk2
make
sudo cp wrk /usr/local/bin
cd ..

# Install fish shell, cuz that's what record_perf.sh is written in
sudo apt install fish

sudo apt install cpulimit
# Set up echo server with Envoy proxy OR
# kubectl apply -f echo.proxy.yaml

# Setup echo server and its Envoy proxy
# docker compose up -d
# envoy -c envoy-demo.yaml --concurrency #

echo "RMINDER: turn off SMT, run:
sudo su - 
echo off > /sys/devices/system/cpu/smt/control"
