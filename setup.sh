# Install packages

sudo swapoff -a
ARCH=$(dpkg --print-architecture)
OS=$(lsb_release -cs)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/apt-key.gpg
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $OS stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/apt-key.gpg] https://apt.kubernetes.io/ \
#   kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# Install kubeadm
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo apt-get install -y kubelet kubeadm kubectl

sudo usermod -aG docker $USER
rm /etc/containerd/config.toml
sudo systemctl restart containerd

sudo kubeadm init
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint nodes desktop node-role.kubernetes.io/control-plane-

curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml -O
# Edit CIDR/Subnet, IP_AUTODETECT if calico fails
kubectl apply -f calico.yaml

#Install Istio
curl -L https://istio.io/downloadIstio | sh -
#cd istio-1.16.1/
cd istio-*/
bin/istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled

# Join using the following output
sudo kubeadm token create --print-join-command

# Install perf tools
sudo apt install linux-tools-common linux-tools-generic linux-tools-$(uname -r)

# Install wrk2
git clone https://github.com/giltene/wrk2.git
cd wrk2
make
sudo cp wrk /usr/local/bin
cd ..

# Install fish shell
sudo apt install fish

# Set up echo server with Envoy proxy
kubectl apply -f echo.proxy.yaml

echo "Done setting up service mesh and echo server"
# Need to turn off SMT, taskset proxy to 1 core
# sudo su -
# echo off > /sys/devices/system/cpu/smt/control