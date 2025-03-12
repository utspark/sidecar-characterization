#!/bin/bash

for (( i=1; i<=6; i++ ))
do
	kubectl top nodes >> $1/top_$2
	sleep 12
done
