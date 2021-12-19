#! /usr/bin/sh
# save current directory
cwd=$(pwd)

# 1. install lighttpd
apt-get install lighttpd 
# 2. download alpine linux, and unzip into
rm -f alpine-rpi-3.15.0-armhf.tar.gz*
wget https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/armhf/alpine-rpi-3.15.0-armhf.tar.gz
rm -rf /var/lib/clusterctrl/nfs/boot
mkdir /var/lib/clusterctrl/nfs/boot
tar -xvf alpine-rpi-3.15.0-armhf.tar.gz -C /var/lib/clusterctrl/nfs/boot
# 3. remove fluff
cd /var/lib/clusterctrl/nfs/boot
# I like to remove all unused files by pi zero. Change below lines if you're using pi zero 2 
rm -f *rpi-{1,2,3,4,a,b,cm}*.dtb
 
# 4. copy fixup_cd and start_cd
# need below 2 files to be able to set gpu_mem=16
cp /boot/fixup_cd.dat .
cp /boot/start_cd.elf .

# 5. move apks out
mv apks ../
# 6. update cmdline.txt
cat <<EOF > cmdline.txt
modules=loop,squashfs,sd-mod,usb_storage,u_ether,u_serial console=ttyS0,115200 console=ttyAMA0 ip=172.19.180.1::172.19.180.254:255.255.255.0:p1:usb0.10:static modloop=http://172.19.180.254/modloop-rpi alpine_repo=http://172.19.180.254/apks apkovl=http://172.19.180.254/p1.apkovl.tar.gz
EOF

# 7. update config.txt [remove last line, add 3 lines]
mv config.txt config.old
head -n -1 config.old > config.txt
cat <<EOF >> config.txt
dtoverlay=dwc2,dr_mode=peripheral
enable_uart=1
gpu_mem=16
EOF

#8. update initramfs-rpi
#	a) unzip, 
rm -rf /tmp/initfs
mkdir /tmp/initfs
cd /tmp/initfs
mv /var/lib/clusterctrl/nfs/boot/boot/initramfs-rpi /var/lib/clusterctrl/nfs/boot/boot/initramfs-rpi.old
zcat /var/lib/clusterctrl/nfs/boot/boot/initramfs-rpi.old|cpio -idmv
#	b) update init
cp "$cwd"/mkinitfs/initramfs-init init
#	c) copy in modules
mkdir modloop
mount -t squashfs /var/lib/clusterctrl/nfs/boot/boot/modloop-rpi /tmp/initfs/modloop
cd modloop/modules/5.15.4-0-rpi
rsync -av --files-from $cwd/mkinitfs/features.d/usb_g.modules . /tmp/initfs/lib/modules/5.15.4-0-rpi
#	d) zip backup
cd /tmp/initfs
umount /tmp/initfs/modloop
rmdir /tmp/initfs/modloop
find . -print0| cpio --null --create --verbose --owner root:root --format=newc|gzip -9 > /var/lib/clusterctrl/nfs/boot/boot/initramfs-rpi

#	e) cleanup
cd /tmp/
rm -rf /tmp/initfs

# 9. update headless overlay file
#	a) download
wget https://github.com/davidmytton/alpine-linux-headless-raspberrypi/releases/download/2021.06.23/headless.apkovl.tar.gz
#	b) unzip 
mkdir /tmp/apkovl
tar -xvf headless.apkovl.tar.gz -C /tmp/apkovl
cd /tmp/apkovl
#	c) update /etc/init.d/hostname
mkdir -p etc/init.d
cp $cwd/files/etc/init.d/hostname etc/init.d/hostname
#	d) update lbu commit config to include etc/init.d/hostname
#	e) zip it backup
cd /tmp
rm headless.apkovl.tar.gz
tar -czf p1.apkovl.tar.gz -C apkovl .
mv p1.apkovl.tar.gz /var/lib/clusterctrl/nfs/p4/
# 	f) cleanup
rm -rf apkovl


# 10. link lighttpd to the modloop
cd /var/www/html
ln -s /var/lib/clusterctrl/nfs/boot/boot/modloop-rpi
ln -s /var/lib/clusterctrl/nfs/apks/
ln -s /var/lib/clusterctrl/nfs/p4/p1.apkovl.tar.gz




