#!/bin/bash

BUILD_ROOT=`pwd`
cd $BUILD_ROOT
repo sync
. build/envsetup.sh

# parse options
while getopts ":c :o:" opt
do
    case "$opt" in
        c) CLEAN=true;;
        o)
             THEME_VENDOR="$OPTARG"
             echo "using $THEME_VENDOR vendorsetup.sh"
        ;;
        \?)
             echo "invalid option: -$OPTARG"
             echo "exiting..."
             exit 1
        ;;
    esac
done

# check for clean
if [ "$CLEAN" = "true" ]; then
    echo "sanitizing build enviornment"
    rm -rf out
    rm .bot_lunch
fi

# Check for add_kernel_manifest (mostly just for aokp).
if [ -f platform_manifest/add_kernel_manifest.sh ]; then
	echo "kernel manifest exists, syncing kernel sources"
	./platform_manifest/add_kernel_manifest.sh
fi

# find the ROM vendor from the manifest path for Pseudo
ROM_VENDOR=$(grep pseudo_buildbot .repo/manifest.xml | cut -f4 -d ' ' | cut -f2 -d '/')

# see if we are using a theme overlay or the ROM's vendorsetup
if [ "$THEME_VENDOR" != "" ]; then
    # using a theme overlay
    VENDOR="$THEME_VENDOR"
else
    # find the ROM vendor from the manifest path for Pseudo
    VENDOR="$ROM_VENDOR"
fi

# make sure file exists
if [ ! -f vendor/$VENDOR/vendorsetup.sh ]; then
    echo "vendorsetup.sh not found"
    echo "exiting..."
    exit 1
fi

# aokp_vzwtab-userdebug
cat vendor/$VENDOR/vendorsetup.sh | cut -f2 -d ' ' > .bot_lunch

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
