#!/bin/bash

boot_dir="BOOT"
data_dir="DATA"
iso_mount_dir="ISO"
kickstart_file="ks.cfg"
src_iso="$1"
device="$2"
boot_part="${device}1"
data_part="${device}2"

# mbr_path_deb="/usr/lib/SYSLINUX/mbr.bin"
# mbr_path_rh="/usr/share/syslinux/mbr.bin"

## Check path to mbr.bin. May be different on other OS.
# [ -f $mbr_path_rh ] && mbr_path="$mbr_path_rh"
# [ -f $mbr_path_deb ] && mbr_path="$mbr_path_deb"

error_package() {
    ERR="Package not availible"
    printf 'ERROR: %s\n' "$ERR" >&2
    exit 1
}

error() {
    ERR="Command FAILED, stopping script"
    printf 'ERROR: %s\n' "$ERR" >&2
    exit 1
}

echo "Checking for packages:"

echo "syslinux"
which syslinux || error_package

echo "sfdisk"
which sfdisk || error_package

echo "mkdosfs"
which mkdosfs || error_package

echo "mkfs"
which mkfs || error_package

echo "e2label"
which e2label || error_package

echo "dd"
which dd || error_package

echo "sed"
which sed || error_package


if [ -z "$device" ] || [ -z "src_iso" ]; then
    error "Wrong arguments!"
    echo "Usage: $0 <CentOS.iso> </dev/usb/flash/drive>"
    exit 22
fi

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
		partprobe $2

		echo "Creating msdosfs on $boot_part ---------------------------"
		mkdosfs $boot_part || error

                echo "Creating fat partition on $boot_part and setting label BOOT -----------------------------"
	        mkfs -t vfat -n "BOOT" $boot_part || error

                echo "Creating ext4 partition on $data_part -----------------------------"
	        mkfs -t ext4 $data_part || error

                echo "Setting label DATA on $data_part partition -----------------------------"
	        e2label $data_part DATA || error

		echo "Updating DB"
		updatedb
		echo "Looking for mbr.bin location ----------------------------"
		mbr_location=$(locate -i syslinux/mbr.bin)

                echo "Writing MBR to device -----------------------------"
	        dd conv=notrunc bs=440 count=1 if=$mbr_path of=$device || error

                echo "Installing syslinux to BOOT partition -----------------------------"
	        syslinux $boot_part || error

                echo "Creating tmp directories and mounting device and ISO image -----------------------------"
		mkdir $boot_dir
	        mount $boot_part $boot_dir || error
		mkdir $data_dir
	        mount $data_part $data_dir || error
		mkdir $iso_mount_dir
	        mount -o loop $src_iso $iso_mount_dir || error
                echo "Copying isolinux/* contents to BOOT partition of device -----------------------------"
	        cp $iso_mount_dir/isolinux/* $boot_dir/ || error
                echo "Renaming isolinux.cfg to syslinux.cfg -----------------------------"
	        mv $boot_dir/isolinux.cfg $boot_dir/syslinux.cfg || error
		echo "Editing syslinux.cfg -----------------------------"
		echo "Changing timeout of menu to 5 sec"
	        sed -i 's/timeout.*/timeout 50/g' $boot_dir/syslinux.cfg || error
		echo "Removing previous default menu items"
	        sed -i '/  menu default/d' $boot_dir/syslinux.cfg || error
		echo "Adding pointer before first menu item"
	        sed -i 's/label linux/pointer\n&/' $boot_dir/syslinux.cfg || error
		echo "Inserting new menu item from file"
	        sed -i '/.*pointer.*/r menu_usb.cfg' $boot_dir/syslinux.cfg || error
		echo "Removing pointer"
	        sed -i '/pointer/d' $boot_dir/syslinux.cfg || error
                echo "Copying ISO image to DATA partition of device -----------------------------"
	        cp $src_iso $data_dir/ || error
		echo "Copy our Kickstart script to the BOOT partition of device"
	        cp $kickstart_file $boot_dir/ks.cfg || error
                echo "Unmounting device and ISO image -----------------------------"
                umount $iso_mount_dir
	        echo "Unmounting flash usb drive dirs -------------------"
		umount $boot_dir
		umount $data_dir
#		echo "removing tmp directories -----------------------------"
#		rm -rf $boot_dir
#		rm -rf $data_dir
#		rm -rf $iso_mount_dir
		echo "DONE -----------------------------"
	else
		echo "Device still mounted, please unmount the device. -----------------------------"
	fi
else
	echo "Deleting of all data on device not comfirmed -----------------------------"
fi
