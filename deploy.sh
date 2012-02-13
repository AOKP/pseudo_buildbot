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
cd ..
$BUILDBOT/build_device.sh 7 maguro
$BUILDBOT/build_device.sh 8 toro
$BUILDBOT/build_device.sh 5 crespo
$BUILDBOT/build_device.sh 6 crespo4g
$BUILDBOT/build_device.sh 9 p4wifi
$BUILDBOT/build_device.sh 10 tenderloin
$BUILDBOT/build_device.sh 11 vivow
$BUILDBOT/build_device.sh 12 p4
$BUILDBOT/build_device.sh 13 p4vzw
$BUILDBOT/build_device.sh 10 tenderloin
$BUILDBOT/build_device.sh 11 vivow
$BUILDBOT/build_device.sh 14 stingray
$BUILDBOT/build_device.sh 15 wingray
$BUILDBOT/build_device.sh 16 supersonic
$BUILDBOT/build_device.sh 17 inc
$BUILDBOT/build_device.sh 18 vzwtab
cd upload

# done!
md5sum aokp_*
