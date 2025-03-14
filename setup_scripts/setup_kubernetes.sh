#!/bin/bash
# Install packages

if [[ $1 == "clean" ]]; then
	sudo kubeadm reset
	> join_command
	rm calico.yaml
else
	sudo swapoff -a
	sudo systemctl stop firewalld
	ARCH=$(dpkg --print-architecture)
	OS=$(lsb_release -cs)
	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/apt-key.gpg
	echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/apt-key.gpg] https://apt.kubernetes.io/ \
		kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

	# Install kubeadm
	# sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
	# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
	
	sudo apt-get update
	sudo apt-get install -y gnupg-agent software-properties-common
	sudo apt-get install -y kubelet kubeadm kubectl
	
	if [[ $1 == "master" ]]; then
		> join_command
		sudo kubeadm init
		mkdir -p $HOME/.kube
		sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
		sudo chown $(id -u):$(id -g) $HOME/.kube/config
		# Untaint control plane node (for single node cluster)
		node=$(kubectl get nodes | awk 'FNR==2{split($0,a); print a[1]}')
		kubectl taint nodes $node node-role.kubernetes.io/control-plane-
		
		curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml -O
		# Edit CIDR/Subnet, IP_AUTODETECT if calico fails
		kubectl apply -f calico.yaml
		kubectl apply -f components.yaml
		
		# Join using the following output
		sudo kubeadm token create --print-join-command > join_command
	else
		while [ ! -s join_command ]
		do
			sleep 5
		done
		sudo bash join_command
	fi
fi
