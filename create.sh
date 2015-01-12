#~/bin/bash
src_iso=$1
dst_iso="CentOS-repacked.iso"
tmp_mount_dir="mount"
working_dir="repacked"
kickstart_file="ks.cfg"

echo "Creating a directory to mount iso source"
mkdir $tmp_mount_dir

echo "Loop mounting the source ISO we are modifying"
mount -o loop $src_iso $tmp_mount_dir

echo "Creating a working directory for our customized media"
mkdir $working_dir

echo "Copying the source media to the working directory"
cp -r $tmp_mount_dir/* $working_dir/

echo "Unmounting the source ISO and removing the directory"
umount $tmp_mount_dir
rmdir $tmp_mount_dir

echo "Changing permissions on the working directory"
chmod -R u+w $working_dir

echo "Editing timeout of boot menu"
sed -i 's/timeout.*/timeout 50/g' $working_dir/isolinux/isolinux.cfg

echo "Removing previous default menu items"
sed -i '/  menu default/d' $working_dir/isolinux/isolinux.cfg

echo "Adding pointer before first menu item"
sed -i 's/label linux/pointer\n&/' $working_dir/isolinux/isolinux.cfg

echo "Inserting new menu item from file"
sed -i '/.*pointer.*/r menu.cfg' $working_dir/isolinux/isolinux.cfg

echo "Removing pointer"
sed -i '/pointer/d' $working_dir/isolinux/isolinux.cfg

echo "Copy our Kickstart script to the working directory"
cp $kickstart_file $working_dir/ks.cfg

echo "Creating the new ISO file"
genisoimage -untranslated-filenames -volid 'CentOS 7 x86_64' -J -joliet-long -rational-rock -translation-table -input-charset utf-8 -x ./lost+found -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -o $dst_iso -T $working_dir/ ; isohybrid -u $src_iso

echo "Removing working directory"
rm -rf $working_dir
