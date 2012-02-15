#!/bin/bash

# setup folders
#OUTD=$(echo $(cd ../test && pwd))
#rm -R $OUTD
#mkdir $OUTD

# clean
BUILD_ROOT=`pwd`
echo "$BUILD_ROOT"
cd $BUILD_ROOT
#repo sync
. build/envsetup.sh

if [ "$1" = "clean" ]; then
	make clean
fi

#
# build_device <lunch combo> <device name>
#
#cd $BUILDBOT
#./build_device.sh 8 toro
./vendor/aokp/bot/build_device.sh 8 toro
./vendor/aokp/bot/build_device.sh 9 p4wifi

#cd $OUTD

# done!
#md5sum aokp_*
