#!/bin/bash

BUILD_ROOT=~/aokp
# $1 should be lunch combo
# $2 should be device name

#BUILD=$(cat $BUILD_ROOT/vendor/aokp/products/common_versions.mk | grep build- | cut -f2 -d '-' | cut -f1 -d ' ')
BUILD=$(cat $BUILD_ROOT/vendor/aokp/products/common_versions.mk | grep "TARGET_PRODUCT" | cut -f3 -d '_' | cut -f1 -d ' ')
#BUILD=milestone-2
#NAME=aokp_$2_$BUILD.zip
NAME=aokp_$2_$BUILD.zip

# build
cd $BUILD_ROOT
. build/envsetup.sh
lunch $1
#make -j`grep 'processor' /proc/cpuinfo | wc -l` otapackage
make -j9 otapackage
make otapackage bacon
ZIP=$(find $BUILD_ROOT/out/target/product/$2/ -maxdepth 1 -name aokp_$2*-squished.zip)
cp $ZIP /home/roman/upload/$NAME

# upload
cd $BUILD_ROOT
cd ../upload

rsync -avP -e "ssh" ./$NAME goo:/home/roman/roms_html/$2/$NAME &
rsync -avP -e "ssh" ./$NAME inffy:/home/teamkang/public_html/roms/$2/$NAME &
rsync -avP -e "ssh" ./$NAME maddler:/home/teamkang/www/$2/$NAME &

#sftp goo <<EOF
#mkdir ./roms_html/$2
#put ./$NAME ./roms_html/$2/$NAME
#quit
#EOF

#sftp inffy <<EOF
#mkdir /home/teamkang/public_html/roms/$2
#put ./$NAME /home/teamkang/public_html/roms/$2/$NAME
#quit
#EOF

#sftp maddler <<EOF
#mkdir /home/teamkang/www/$2
#put ./$NAME /home/teamkang/www/$2/$NAME
#quit
#EOF
