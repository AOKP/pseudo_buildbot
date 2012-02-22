#!/bin/bash

# $1 should be lunch combo
# $2 should be device name
# select device and prepare varibles
BUILD_ROOT=`pwd`
cd $BUILD_ROOT
. build/envsetup.sh
lunch $1

TARGET_VENDOR=$(echo $TARGET_PRODUCT | cut -f1 -d '_')

# create log dir if not already present
if test ! -d "$ANDROID_PRODUCT_OUT"
    echo "$ANDROID_PRODUCT_OUT doesn't exist, creating now"
    then mkdir -p "$ANDROID_PRODUCT_OUT"
fi

# build
make -j$(grep processor /proc/cpuinfo | wc -l) bacon 2>&1 | tee "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log

# clean out of previous zip
ZIP=$(tail -2 "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')
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

cd $BUILT_ROOT
