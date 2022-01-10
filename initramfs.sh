#! /usr/bin/bash
# save current directory
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

#	a) unzip, 
rm -rf /tmp/initfs
mkdir /tmp/initfs
cd /tmp/initfs
mv /var/lib/clusterctrl/nfs/boot/boot/initramfs-rpi /var/lib/clusterctrl/nfs/boot/boot/initramfs-rpi.old
zcat /var/lib/clusterctrl/nfs/boot/boot/initramfs-rpi.old|cpio -idmv
#	b) update init
cp $SCRIPTPATH/mkinitfs/initramfs-init init
#	c) copy in modules
mkdir modloop
mount -t squashfs /var/lib/clusterctrl/nfs/boot/boot/modloop-rpi /tmp/initfs/modloop
cd modloop/modules/5.15.4-0-rpi
rsync -av --files-from $SCRIPTPATH/mkinitfs/features.d/usb_g.modules . /tmp/initfs/lib/modules/5.15.4-0-rpi
#	d) zip backup
cd /tmp/initfs
umount /tmp/initfs/modloop
rmdir /tmp/initfs/modloop
depmod -b /tmp/initfs/ 5.15.4-0-rpi
find . -print0| cpio --null --create --verbose --owner root:root --format=newc|gzip -9 > /var/lib/clusterctrl/nfs/boot/boot/initramfs-rpi

#	e) cleanup
cd /tmp/
rm -rf /tmp/initfs

