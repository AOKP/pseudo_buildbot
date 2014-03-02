#!/bin/bash

# $1 should be lunch combo
# $2 should be device name
# $3 should be build number (if applicable)
# select device and prepare varibles
DATE=$(date +%h-%d-%y)
LOG_DIR=logs
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

# host OS check
if [ "$(uname -s)" = "Darwin" ]; then
    LOLMAC=true
fi

# create log dir if not already present
if test ! -d "$LOG_DIR"
    echo "log directory doesn't exist, creating now"
    then mkdir -p "$LOG_DIR"
fi

# build
if [ "$BACON" = "true" ]; then
    if [ "$LOLMAC" = "true" ]; then
        make -j `sysctl hw.ncpu|cut -d" " -f2` bacon 2>&1 | tee "$LOG_DIR"/"$TARGET_PRODUCT"_"$DATE"_bot.log
    else
        schedtool -B -n 1 -e ionice -n 1 make -j `cat /proc/cpuinfo | grep "^processor" | wc -l` bacon 2>&1 | tee "$LOG_DIR"/"$TARGET_PRODUCT"_"$DATE"_bot.log
    fi
elif [ "$LOLMAC" = "true" ]; then
    make -j `sysctl hw.ncpu|cut -d" " -f2` otapackage 2>&1 | tee "$LOG_DIR"/"$TARGET_PRODUCT"_"$DATE"_bot.log
else
    schedtool -B -n 1 -e ionice -n 1 make -j `cat /proc/cpuinfo | grep "^processor" | wc -l` otapackage 2>&1 | tee "$LOG_DIR"/"$TARGET_PRODUCT"_"$DATE"_bot.log
fi

# clean out of previous zip
if [ "$BACON" = "true" ]; then
    ZIP=$(basename $(tail -5 "$LOG_DIR"/"$TARGET_PRODUCT"_"$DATE"_bot.log | head -1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | cut -f2 -d ' '))
else
    ZIP=$(basename $(grep "Package OTA" "$LOG_DIR"/"$TARGET_PRODUCT"_"$DATE"_bot.log | cut -f3 -d ' '))
fi

BUILDBOT=$BUILD_ROOT/vendor/$TARGET_VENDOR/bot/

# execute finishing scripts (md5, upload, etc) only if the build was successful (ie. actually produced a .zip)
if [[ $ZIP == *.zip* ]]; then
    # finish
    echo "$2 build complete"
    OUTD="../upload"
    if [ ! -d "$OUTD/" ]; then
        mkdir "$OUTD"
    fi
    # Convert $OUTD into an absolute path
    OUTDL=$(echo $(cd "$OUTD" && pwd))
    if [ -f "$OUTDL/$ZIP" ]; then
        rm $OUTDL/$ZIP
    fi
    if [ -n "$3" ]; then
        NZIP="$TARGET_PRODUCT"_kitkat_"$3".zip
        cp "$ANDROID_PRODUCT_OUT"/$ZIP $OUTDL/$NZIP
    else
        cp "$ANDROID_PRODUCT_OUT"/$ZIP $OUTDL/$ZIP
    fi

    # md5sum list
    cd $OUTDL
    md5sum $ZIP | cat >> md5sum

    # upload
    echo "checking on upload reference file"

    cd $BUILDBOT
    if test -x upload ; then
        echo "Upload file exists, executing now"
        cp upload $OUTDL
        cd $OUTDL
        # device and zip names are passed on for upload
        ./upload $2 $ZIP && rm upload
    else
        echo "No upload file found (or set to +x), build complete."
    fi

else
    cd $BUILDBOT
    if test -x report_fail ; then
        ./report_fail $2
    fi
    echo "$2 build failed, exiting"
fi

cd $BUILD_ROOT

# remove device specific out files to save space on SSD
if [ "$SMALL_DISK" = 1 ]; then
    rm -rf $ANDROID_PRODUCT_OUT
fi
