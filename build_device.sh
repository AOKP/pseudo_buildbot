#!/bin/bash

# select device and prepare varibles
BUILD_ROOT=`pwd`
cd $BUILD_ROOT
. build/envsetup.sh
lunch $1

TARGET_VENDOR=$(echo $TARGET_PRODUCT | cut -f1 -d '_')
VER=$(cat vendor/$TARGET_VENDOR/products/common_versions.mk | grep "TARGET_PRODUCT" | cut -f3 -d '_' | cut -f1 -d ' ')
ZIP=$(find $(echo $ANDROID_PRODUCT_OUT) -maxdepth 1 -name $TARGET_VENDOR_*-squished.zip)
OUTD=$(echo $(cd ../test && pwd))
#ZIP=/home/khasmek/Android/AOKP/out/target/product/toro/aokp_toro_build-23-squished.zip

# $1 should be lunch combo
# $2 should be device name

# build
make -j9 bacon
#ZIP=$(find $(echo $ANDROID_PRODUCT_OUT) -maxdepth 1 -name $TARGET_VENDOR_$2*-squished.zip)
#OUTD=$(echo $(cd ../test && pwd))
# clean out of previous zip
OUTZ=$(echo $TARGET_PRODUCT)_$VER.zip
rm -rf $OUTD/$OUTZ
#mkdir $OUTD
#NAME=aokp_$2_$BUILD.zip
cp $ZIP $OUTD/$OUTZ

# finish
echo "$2 build complete"

# md5sum list
cd $OUTD
#md5sum aokp_*
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
