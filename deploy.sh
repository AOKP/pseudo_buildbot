#!/bin/bash

# clean
BUILD_ROOT=`pwd`
cd $BUILD_ROOT
#repo sync
. build/envsetup.sh

if [ "$1" = "clean" ]; then
	make clean
fi

#
# build_device <lunch combo> <device name>
#
./vendor/aokp/bot/build_device.sh 8 toro
./vendor/aokp/bot/build_device.sh 9 p4wifi
