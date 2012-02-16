#!/bin/bash

# select device and prepare varibles
BUILD_ROOT=`pwd`
cd $BUILD_ROOT
. build/envsetup.sh
lunch $1

TARGET_VENDOR=$(echo $TARGET_PRODUCT | cut -f1 -d '_')
VER=$(cat vendor/$TARGET_VENDOR/products/common_versions.mk | grep "TARGET_PRODUCT" | cut -f3 -d '_' | cut -f1 -d ' ')
ZIP=$(find $(echo $ANDROID_PRODUCT_OUT) -maxdepth 1 -name $(echo $TARGET_PRODUCT)_*-squished.zip)
OUTD=$(echo $(cd ../upload && pwd))

# $1 should be lunch combo
# $2 should be device name

# build
make -j$(grep processor /proc/cpuinfo | wc -l) bacon

# clean out of previous zip
OUTZ=$(echo $TARGET_PRODUCT)_$VER.zip
rm -rf $OUTD/$OUTZ
cp $ZIP $OUTD/$OUTZ

# finish
echo "$2 build complete"

# md5sum list
cd $OUTD
md5sum $OUTZ | cat >> md5sum

# upload
echo "checking on upload reference file"

BUILDBOT=$BUILD_ROOT/vendor/$TARGET_VENDOR/bot/
cd $BUILDBOT
if test -x upload ; then
        echo "Upload file exists, executing now"
        cp upload $OUTD
        cd $OUTD
        ./upload $2 && rm upload
else
        echo "No upload file found (or set to +x), build complete."
fi

cd $BUILT_ROOT
