#!/bin/bash

# If debug is true, it won't sync or modify .bot_lunch
debug=
BUILD_ROOT=`pwd`
cd $BUILD_ROOT
if [ -z "$debug" ]; then
    repo sync
    . build/envsetup.sh
fi

BUILDN=
# parse options
while getopts ":c :o: :b: " opt
do
    case "$opt" in
        c) CLEAN=true;;
        o)
             THEME_VENDOR="$OPTARG"
             echo "using $THEME_VENDOR vendorsetup.sh"
             ;;
        b)
             BUILDN="$OPTARG"
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

if [[ -z "$debug" && ! -f .bot_lunch ]]; then
    # aokp_vzwtab-userdebug
    cat vendor/$VENDOR/vendorsetup.sh | cut -f2 -d ' ' > .bot_lunch
fi

# build packages
#
# read the file and execute lunch
while read line ;do
    # vzwtab
    DEVNAME=$(echo $line | cut -f2 -d ' ' | cut -f2 -d '_' | cut -f1 -d '-')
    # build_device <lunch combo> <device name>
    if [ -n "$BUILDN" ]; then
        ./vendor/$ROM_VENDOR/bot/build_device.sh $line $DEVNAME $BUILDN
    else
        ./vendor/$ROM_VENDOR/bot/build_device.sh $line $DEVNAME
    fi
done < .bot_lunch

# Tag repo if declared
if [ -n "$BUILDN" ]; then
    grep AOKP/ .repo/manifest.xml | cut -f4 -d '"' > .repo_list
    grep AOKP/ .repo/manifest.xml | cut -f2 -d '"' > .dir_list

    exec 11<.dir_list
    exec 12<.repo_list

    repo manifest -r -o $BUILDN-manifest.xml
    sed -i '/</!s/^[ ^t]*//' $BUILDN-manifest.xml
    find . -name .git -execdir git tag -a "$BUILDN" -m "$BUILDN" \;
    while read -u 11 DIR && read -u 12 REPO_DIR ;do
        cd $DIR
        "git push gerrit:/$REPO_DIR {$3}"
    done

    exec 11<&- 12<&-
    rm .dir_list .repo_list
fi

# don't be messy unless you're testie
if [ -z "$debug" ]; then
    rm .bot_lunch
fi
