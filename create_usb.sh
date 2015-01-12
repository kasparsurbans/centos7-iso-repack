#!/bin/bash
boot_dir="BOOT"
data_dir="DATA"
iso_mount_dir="ISO"
kickstart_file="ks.cfg"
src_iso=$1
device=$2
boot_part=${device}1
data_part=${device}2

echo "The device selected currently has these partitions:"
echo "---------------------------------------------------"
sfdisk -l $device
echo "---------------------------------------------------"
echo "All data on this device will be lost. Please comfirm typing: yes and hit [ENTER]"
read choice

if [ "$choice" == "yes" ]
then
	echo "Deleting of all data on device comfirmed -----------------------------"
	sfdisk -R $device
	if [ $? == 0 ]
	then
		echo "Device not mounted - GOOD -----------------------------"
		echo "Creating partitions -----------------------------"
		sfdisk $device -uM < layout
                echo "Reloading partitions -----------------------------"
		partprobe
		echo "Creating msdosfs on $boot_part ---------------------------"
		mkdosfs $boot_part
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Creating fat partition on $boot_part and setting label BOOT -----------------------------"
		mkfs -t vfat -n "BOOT" $boot_part
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Creating ext4 partition on $data_part -----------------------------"
		mkfs -t ext4 $data_part
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Setting label DATA on $data_part partition -----------------------------"
		e2label $data_part DATA
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Writing MBR to device -----------------------------"
		dd conv=notrunc bs=440 count=1 if=/usr/lib/syslinux/mbr.bin of=$device
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Installing syslinux to BOOT partition -----------------------------"
		syslinux $boot_part
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Creating tmp directories and mounting device and ISO image -----------------------------"
		mkdir $boot_dir
		mount $boot_part $boot_dir
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
		mkdir $data_dir
		mount $data_part $data_dir
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
		mkdir $iso_mount_dir
		mount $src_iso $iso_mount_dir
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Copying isolinux/* contents to BOOT partition of device -----------------------------"
		cp $iso_mount_dir/isolinux/* $boot_dir/
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Renaming isolinux.cfg to syslinux.cfg -----------------------------"
		mv $boot_dir/isolinux.cfg $boot_dir/syslinux.cfg
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
		echo "Editing syslinux.cfg -----------------------------"
		echo "Changing timeout of menu to 5 sec"
		sed -i 's/timeout.*/timeout 50/g' $boot_dir/syslinux.cfg
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
		echo "Removing previous default menu items"
		sed -i '/  menu default/d' $boot_dir/syslinux.cfg
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
		echo "Adding pointer before first menu item"
		sed -i 's/label linux/pointer\n&/' $boot_dir/syslinux.cfg
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
		echo "Inserting new menu item from file"
		sed -i '/.*pointer.*/r menu_usb.cfg' $boot_dir/syslinux.cfg
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
		echo "Removing pointer"
		sed -i '/pointer/d' $boot_dir/syslinux.cfg
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Copying ISO image to DATA partition of device -----------------------------"
		cp $src_iso $data_dir/
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
		echo "Copy our Kickstart script to the BOOT partition of device"
		cp $kickstart_file $boot_dir/ks.cfg
		if [ $? != 0 ]; then echo "Command FAILED, stopping script";exit; fi
                echo "Unmounting ISO image -----------------------------"
		umount $iso_mount_dir
		echo "DONE -----------------------------"
	else
		echo "Device still mounted, please unmount the device. -----------------------------"
	fi
else
	echo "Deleting of all data on device not comfirmed -----------------------------"
fi
