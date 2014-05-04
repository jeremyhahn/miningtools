#!/bin/bash

unzip amd-catalyst-14-4-linux-x86-x86-64.zip
cd fglrx-14.10.100
chmod amd-driver-installer-14.10.1006-x86.x86_64.run
./amd-driver-installer-14.10.1006-x86.x86_64.run
cd ..

tar xzvf AMD-APP-SDK-v2.9-lnx64.tgz
./Install-AMD-APP.sh

unzip ADL_SDK_6.0.zip

git clone https://github.com/sgminer-dev/sgminer.git
cp include/adl_* sgminer/ADL_SDK
cd sgminer
./autogen.sh
CFLAGS="-O3 -Wall -march=native -I /opt/AMDAPP/include" LDFLAGS="-L/opt/AMDAPP/lib/x86_64" ./configure --enable-opencl --enable-scrypt
make install
