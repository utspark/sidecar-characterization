#!/bin/bash

sudo apt install -y cpufrequtils
sudo modprobe acpi-cpufreq
echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
echo "GOVERNOR=\"performance\"" | sudo tee /etc/default/cpufrequtils
echo "1" | sudo tee /sys/devices/system/cpu/cpu*/cpuidle/state*/disable
sudo systemctl disable ondemand
sudo systemctl daemon-reload
sudo systemctl enable cpufrequtils
#more /proc/cpuinfo | grep "MHz"
