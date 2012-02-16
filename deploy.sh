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
./vendor/aokp/bot/build_device.sh 7 maguro
./vendor/aokp/bot/build_device.sh 8 toro
./vendor/aokp/bot/build_device.sh 5 crespo
./vendor/aokp/bot/build_device.sh 6 crespo4g
./vendor/aokp/bot/build_device.sh 9 p4wifi
./vendor/aokp/bot/build_device.sh 10 tenderloin
./vendor/aokp/bot/build_device.sh 11 vivow
./vendor/aokp/bot/build_device.sh 12 p4
./vendor/aokp/bot/build_device.sh 13 p4vzw
./vendor/aokp/bot/build_device.sh 10 tenderloin
./vendor/aokp/bot/build_device.sh 11 vivow
./vendor/aokp/bot/build_device.sh 14 stingray
./vendor/aokp/bot/build_device.sh 15 wingray
./vendor/aokp/bot/build_device.sh 16 supersonic
./vendor/aokp/bot/build_device.sh 17 inc
./vendor/aokp/bot/build_device.sh 18 vzwtab

