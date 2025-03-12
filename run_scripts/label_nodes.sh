#!/bin/bash

nodes=($(kubectl get nodes -o custom-columns=NAME:.metadata.name | tail -n +2))

for n in "${nodes[@]}"; do
	IFS='.' read -ra token <<< $n
	kubectl label nodes $n worker=${token[0]} 
done
