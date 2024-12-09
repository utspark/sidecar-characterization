#!/bin/bash
ARCH=$(dpkg --print-architecture)
OS=$(lsb_release -cs)

# Install Docker
sudo apt-get update
sudo apt-get install -y ca-certificates apt-transport-https gnupg2 curl lsb-release luarocks htop fish inotify-tools
sudo luarocks install luasocket

# Add PPA repos
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch="$ARCH" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $OS stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
#echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
#echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/getenvoy.list
wget -O- https://apt.envoyproxy.io/signing.key | sudo gpg --dearmor -o /etc/apt/keyrings/envoy-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/envoy-keyring.gpg] https://apt.envoyproxy.io bookworm main" | sudo tee /etc/apt/sources.list.d/envoy.list

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo apt-get install -y docker.io docker-compose-plugin # rerunning this line installs docker correctly?
sudo apt install -y mysql-client-core-8.0

# Allow docker commands without sudo
sudo usermod -aG docker $USER
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Envoy
#sudo apt install -y getenvoy-envoy
sudo apt-get install envoy

#Install perf tools
sudo apt install -y linux-tools-common linux-tools-generic linux-tools-$(uname -r) cpulimit
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
echo 0 | sudo tee /proc/sys/kernel/nmi_watchdog

./setup_scripts/setup_dvfs.sh

sudo chsh -s /usr/bin/fish psahu

echo "Close shell and reopen to use docker commands without sudo"
