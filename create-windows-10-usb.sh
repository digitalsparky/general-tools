#!/bin/bash

function help() {
    echo "Usage: $0 WindowsIsoPath.iso /dev/device"
    echo "Eg: $0 windows10.iso /dev/sdd"
    exit 0
}

iso=$1
dev=$2

if [ `whoami` != "root" ]; then
	echo "This needs to be run as root, sorry, exiting"
	exit 1
fi

if [ ! -f "$iso" ]; then
	echo "$iso is not a valid file or does not exist"
	exit 1
fi

if [ ! -b "$dev" ]; then
	echo "$dev is not a valid block device"
	exit 1
fi

which parted > /dev/null 2>&1
if [ $? -gt 0 ]; then
    echo "Ut oh, parted is missing, can't proceed"
    exit 1
fi

which mkfs.ntfs > /dev/null 2>&1
if [ $? -gt 0 ]; then
    echo "Ut oh, mkfs.ntfs is missing, can't proceed"
    exit 1
fi

which ms-sys > /dev/null 2>&1
if [ $? -gt 0 ]; then
    echo "Ut oh, ms-sys is missing, unable to proceed"
    read -p "Would you like me to install it now? (Y|N): " installNow
    while [[ "$installNow" != "Y" && "$installNow" != "N" ]]; do
        echo "Entered invalid option"
        read -p "Would you like me to install it now? (Y|N): " installNow
    done
    if [ "$installNow" != "Y" ]; then
        echo "Unable to proceed"
        exit 1
    fi
    wget https://launchpad.net/~lenski/+archive/ubuntu/ms-sys/+files/ms-sys_2.2.0-1ubuntu1_amd64.deb -O /tmp/ms-sys.deb
    dpkg -i /tmp/ms-sys.deb
    rm -f /tmp/ms-sys.deb
fi

echo "Are you absolutely sure you want to do this?"
echo "This process will destroy all data on ${dev}"
read -p "Would you like me to begin? (Y|N): " runNow
while [[ "$runNow" != "Y" && "$runNow" != "N" ]]; do
    echo "Entered invalid option"
    read -p "Would you like me to begin? (Y|N): " runNow
done
if [ "$runNow" != "Y" ]; then
    echo "Exiting"
    exit 1
fi

echo "Re-creating partition table on ${dev}"
parted -s $dev mklabel msdos
parted -s -a optimal $dev mkpart primary ntfs 2048s 100%
parted -s $dev set 1 boot on

echo "Creating temporary mount directories"
mkdir /tmp/mountA /tmp/mountB
echo "Mounting ISO to temporary directory"
mount -o loop $iso /tmp/mountA
echo "Formatting ${dev}1"
mkfs.ntfs -f -L win ${dev}1
echo "Writing Boot Sector to ${dev}"
ms-sys -7 ${dev}
echo "Mounting destination to temporary directory"
mount ${dev}1 /tmp/mountB
echo "Copying data from ISO to destination"
rsync -a /tmp/mountA/ /tmp/mountB
echo "Syncing device"
sync ${dev}
echo "Cleaning up"
umount /tmp/mountA /tmp/mountB
rm -rf /tmp/mountA /tmp/mountB
echo "Your Windows USB is now ready for use"
