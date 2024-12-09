#!/bin/bash

sudo apt-get install --no-install-recommends wget make g++
sudo apt-get install --no-install-recommends libstdc++-4.9-dev libssl-dev
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install --no-install-recommends gcc-multilib g++-multilib
sudo apt-get install --no-install-recommends libstdc++-4.9-dev:i386 libssl-dev:i386

wget https://software.intel.com/sites/landingpage/pintool/downloads/pin-3.30-98830-g1d7b601b3-gcc-linux.tar.gz
tar xzf pin-3.30-98830-g1d7b601b3-gcc-linux.tar.gz
mv pin-3.30-98830-g1d7b601b3-gcc-linux /opt
#export PIN_ROOT=/opt/pin-3.30-98830-g1d7b601b3-gcc-linux
#echo -e "\nexport PIN_ROOT=/opt/pin-3.30-98830-g1d7b601b3-gcc-linux" >> ~/.bashrc
