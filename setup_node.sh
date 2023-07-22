
ARCH=$(dpkg --print-architecture)
OS=$(lsb_release -cs)

# Install Docker
sudo apt-get update
sudo apt-get install -y ca-certificates apt-transport-https gnupg2 curl lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch="$ARCH" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $OS stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo apt-get install -y docker.io docker-compose-plugin # rerunning this line installs docker correctly?

# Allow docker commands without sudo
sudo usermod -aG docker $USER
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Envoy
sudo apt update
sudo apt install apt-transport-https gnupg2 curl lsb-release 
curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
# Verify the keyring - this should yield "OK"
echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/getenvoy.list
sudo apt update
sudo apt install -y getenvoy-envoy

#Install perf tools
sudo apt install -y linux-tools-common linux-tools-generic linux-tools-$(uname -r) cpulimit
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
echo 0 | sudo tee /proc/sys/kernel/nmi_watchdog

docker compose up -d

echo "Close shell and reopen to use docker commands without sudo"
