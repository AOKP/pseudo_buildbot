#!/bin/bash

BUILD_ROOT=~/aokp
# $1 should be lunch combo
# $2 should be device name

BUILD=$(cat $BUILD_ROOT/vendor/aokp/products/common_versions.mk | grep "TARGET_PRODUCT" | cut -f3 -d '_' | cut -f1 -d ' ')
NAME=aokp_$2_$BUILD.zip

# build
cd $BUILD_ROOT
. build/envsetup.sh
lunch $1
#make -j`grep 'processor' /proc/cpuinfo | wc -l` otapackage
make -j9 otapackage bacon
ZIP=$(find $BUILD_ROOT/out/target/product/$2/ -maxdepth 1 -name aokp_$2*-squished.zip)
cp $ZIP /home/roman/upload/$NAME

# upload
cd $BUILD_ROOT
cd ../upload

#
# this is kind of dirty nasty, but create directories, then upload
#

sftp goo <<EOF
mkdir ./roms_html/$2
quit
EOF

sftp inffy <<EOF
mkdir /home/teamkang/public_html/roms/$2
quit
EOF

sftp maddler <<EOF
mkdir /home/teamkang/www/$2
quit
EOF

rsync -avP -e "ssh" ./$NAME goo:/home/roman/roms_html/$2/$NAME &
rsync -avP -e "ssh" ./$NAME inffy:/home/teamkang/public_html/roms/$2/$NAME &
rsync -avP -e "ssh" ./$NAME maddler:/home/teamkang/www/$2/$NAME &
