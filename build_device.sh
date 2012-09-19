#!/bin/bash

# $1 should be lunch combo
# $2 should be device name
# select device and prepare varibles
DATE=$(date +%h-%d-%y)
BUILD_ROOT=`pwd`
cd $BUILD_ROOT
. build/envsetup.sh
lunch $1

TARGET_VENDOR=$(echo $TARGET_PRODUCT | cut -f1 -d '_')

# bacon check
if [ "$(grep -m 1 bacon build/envsetup.sh)" = "" ]; then
    echo "Y U NO MAKE BACON?!"
    BACON=false
else
    BACON=true
fi

# mka check
if [ "$(grep -m 1 mka build/envsetup.sh)" = "" ]; then
    echo "Y U WANT SLOW BUILD?!"
    MKA=false
else
    MKA=true
fi

# create log dir if not already present
if test ! -d logs
    echo "log directory doesn't exist, creating now"
    then mkdir -p logs
fi

# build
if [ "$BACON" = "true" ]; then
    if [ "$MKA" = "true" ];then
        mka bacon 2>&1 | tee logs/"$TARGET_PRODUCT"_"$DATE"_bot.log
    else
        make $(($(grep processor /proc/cpuinfo | wc -l) + 1)) bacon 2>&1 | tee logs/"$TARGET_PRODUCT"_"$DATE"_bot.log
    fi
else
    make $(($(grep processor /proc/cpuinfo | wc -l) + 1)) otapackage 2>&1 | tee logs/"$TARGET_PRODUCT"_"$DATE"_bot.log
fi

# clean out of previous zip
if [ "$BACON" = "true" ]; then
    ZIP=$(tail -2 logs/"$TARGET_PRODUCT"_"$DATE"_bot.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')
else
    ZIP=$(grep "Package OTA" logs/"$TARGET_PRODUCT"_"$DATE"_bot.log | cut -f5 -d '/')
fi
mkdir ../upload
OUTD=$(echo $(cd ../upload && pwd))
rm $OUTD/$ZIP
cp "$ANDROID_PRODUCT_OUT"/$ZIP $OUTD/$ZIP

# finish
echo "$2 build complete"

# md5sum list
cd $OUTD
md5sum $ZIP | cat >> md5sum

# upload
echo "checking on upload reference file"

BUILDBOT=$BUILD_ROOT/vendor/$TARGET_VENDOR/bot/
cd $BUILDBOT
if test -x upload ; then
    echo "Upload file exists, executing now"
    cp upload $OUTD
    cd $OUTD
    # device and zip names are passed on for upload
    ./upload $2 $ZIP && rm upload
else
    echo "No upload file found (or set to +x), build complete."
fi

cd $BUILD_ROOT
