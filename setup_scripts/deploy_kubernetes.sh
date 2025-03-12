# Install packages

if [[ $1 == "clean" ]]; then
	sudo kubeadm reset
	rm calico.yaml
else
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
	
	# Join using the following output
	sudo kubeadm token create --print-join-command
fi
