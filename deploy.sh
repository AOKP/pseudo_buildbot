#!/bin/bash

# clean
BUILD_ROOT=`pwd`
cd $BUILD_ROOT
#repo sync
. build/envsetup.sh

if [ "$1" = "clean" ]; then
	make clean
	rm .bot_lunch
fi

#
# build_device <lunch combo> <device name>
#

# need to fix this
#ROM_VENDOR=$(cat vendor/aokp/vendorsetup.sh | cut -f2 -d ' ' | cut -f1 -d '_' | cut -f1 -d '-')
ROM_VENDOR=aokp

# aokp_vzwtab-userdebug
cat vendor/$ROM_VENDOR/vendorsetup.sh | cut -f2 -d ' ' > .bot_lunch

# read the file and execute lunch/test
while read line ;do
    # vzwtab
    DEVNAME=$(echo $line | cut -f2 -d ' ' | cut -f2 -d '_' | cut -f1 -d '-')
    ./vendor/$ROM_VENDOR/bot/build_device.sh $line $DEVNAME
done < .bot_lunch

rm .bot_lunch
