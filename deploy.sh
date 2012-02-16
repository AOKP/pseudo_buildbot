#!/bin/bash

BUILD_ROOT=`pwd`
cd $BUILD_ROOT
#repo sync
. build/envsetup.sh

# check for clean
if [ "$1" = "clean" ]; then
	make clean
	rm .bot_lunch
fi

# find the ROM vendor from the manifest path for Pseudo
ROM_VENDOR=$(grep pseudo_buildbot .repo/manifest.xml | cut -f4 -d ' ' | cut -f2 -d '/')

# aokp_vzwtab-userdebug
cat vendor/$ROM_VENDOR/vendorsetup.sh | cut -f2 -d ' ' > .bot_lunch

# build packages
#
# read the file and execute lunch
while read line ;do
    # vzwtab
    DEVNAME=$(echo $line | cut -f2 -d ' ' | cut -f2 -d '_' | cut -f1 -d '-')
    # build_device <lunch combo> <device name>
    ./vendor/$ROM_VENDOR/bot/build_device.sh $line $DEVNAME
done < .bot_lunch

# don't be messy
rm .bot_lunch
