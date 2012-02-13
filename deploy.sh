#!/bin/bash

BUILD_ROOT=~/aokp
BUILDBOT=~/buildbot

# setup folders
rm -R ../upload
mkdir ../upload

# clean
cd $BUILD_ROOT
repo sync
. build/envsetup.sh

if [ $1 = "clean" ]; then 
	make clean
fi

#
# build_device <lunch combo> <device name>
#
cd $BUILDBOT
./build_device.sh 7 maguro
./build_device.sh 8 toro
./build_device.sh 5 crespo
./build_device.sh 6 crespo4g
./build_device.sh 9 p4wifi
./build_device.sh 10 tenderloin
./build_device.sh 11 vivow
./build_device.sh 12 p4
./build_device.sh 13 p4vzw
./build_device.sh 10 tenderloin
./build_device.sh 11 vivow
./build_device.sh 14 stingray
./build_device.sh 15 wingray
./build_device.sh 16 supersonic
./build_device.sh 17 inc
./build_device.sh 18 vzwtab

cd ~/upload

# done!
md5sum aokp_*
