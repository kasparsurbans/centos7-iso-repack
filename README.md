# centos7-iso-repack
Tool for repacking CentOS 7 iso, adding KICKSTART config of your choice, editing INSTALL menu to automatically boot your install with KS. All this also possible writing ISO with KS configuration to USB flash. 

!!! WORD of CAUTION. Using usb flash creation skript is very DANGEROUS if you dont know what you are doing. If you specify the wrong device, it will wipe the specified disks clean!!!!

to repack iso do the following:

1. Download Centos 7 ISO into the working dir
2. Edit ks.cfg according to your needs
3. sudo ./create.sh downloaded-iso.iso
4. Burn the newly created CentOS-repacked.iso to CD, DVD or mount it via Virtualbox and use at your own risk :)

to create a bootable usb containing Centos 7 iso with a specific ks.cfg

1. Download Centos 7 ISO into the working dir
2. Edit ks.cfg according to your needs
3. Attach you USB flash
4. Make sure to unmount all mounted USB flash partitions
5. Execute sudo ./create_usb.sh downloaded-iso.iso /dev/path/to/usb/flash ( Example: sudo ./create_usb.sh CentOS-7.0-1406-x86_64-NetInstall.iso /dev/sdc )
   BE VERY CAREFULL WHEN specifying device. All data on it will be lost during this process!!!!!
6. Read instructions on screen, and follow the process.
7. Eject the USB flash and use it as install media for your CentOS install

