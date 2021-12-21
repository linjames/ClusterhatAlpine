#! /usr/bin/bash
# save current directory
cwd=$(pwd)
pushd 
cd /tmp

# 0. for my server
apt-get install screen tmux sysstat ifstat conspy

# 1. install lighttpd
apt-get install -y lighttpd 
# 2. download alpine linux, and unzip into
rm -f alpine-rpi-3.15.0-armhf.tar.gz*
wget https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/armhf/alpine-rpi-3.15.0-armhf.tar.gz
rm -rf /var/lib/clusterctrl/nfs/boot
mkdir /var/lib/clusterctrl/nfs/boot
tar -xvf alpine-rpi-3.15.0-armhf.tar.gz -C /var/lib/clusterctrl/nfs/boot
# 3. remove fluff
cd /var/lib/clusterctrl/nfs/boot
# I like to remove all unused files by pi zero. Change below lines if you're using pi zero 2 
rm *rpi-{2,3,4,a,b,cm}*.dtb
rm boot/*rpi2
 
# 4. copy fixup_cd and start_cd
# need below 2 files to be able to set gpu_mem=16
cp /boot/fixup_cd.dat .
cp /boot/start_cd.elf .

# 5. move apks out
if [ -f ../apks ]; then
	rm -rf apks
else
	mv apks ../
fi
# 6. update cmdline.txt
cat <<EOF > cmdline.txt
modules=loop,squashfs,u_ether,u_serial console=ttyAMA0,115200 ip=172.19.180.1::172.19.180.254:255.255.255.0:p1:usb0.10:static modloop=http://172.19.180.254/modloop-rpi alpine_repo=http://172.19.180.254/apks apkovl=http://172.19.180.254/p1.apkovl.tar.gz
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
depmod -b /tmp/initfs/ 5.15.4-0-rpi
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
tar -czf /var/lib/clusterctrl/nfs/boot/p1.apkovl.tar.gz -C apkovl .
# 	f) cleanup
rm -rf apkovl

# 10. link lighttpd to the modloop
rm /var/www/html/modloop-rpi
rm /var/www/html/apks
rm /var/www/html/p{1,2,3,4}.apkovl.tar.gz
ln -s /var/lib/clusterctrl/nfs/boot/boot/modloop-rpi /var/www/html/modloop-rpi
ln -s /var/lib/clusterctrl/nfs/apks/ /var/www/html/apks

# 11 mount boot 
cd /var/lib/clusterctrl/nfs

sed -i '/nfs\/p[1-4]\/boot/d' /etc/fstab
umount /var/lib/clusterctrl/nfs/p{1,2,3,4}/boot
rm -rf /var/lib/clusterctrl/nfs/p{1,2,3,4}
mkdir -p /var/lib/clusterctrl/nfs/p{1,2,3,4}/{boot,u,w}

for p_num in 1 2 3 4
do
	cp /var/lib/clusterctrl/nfs/boot/p1.apkovl.tar.gz /var/lib/clusterctrl/nfs/p$p_num/p$p_num.apkovl.tar.gz
	ln -s /var/lib/clusterctrl/nfs/p$p_num/p$p_num.apkovl.tar.gz /var/www/html/p$p_num.apkovl.tar.gz
	cat <<EOF >> /etc/fstab
overlayfs	/var/lib/clusterctrl/nfs/p$p_num/boot	overlay		lowerdir=/var/lib/clusterctrl/nfs/boot,workdir=/var/lib/clusterctrl/nfs/p$p_num/w,upperdir=/var/lib/clusterctrl/nfs/p$p_num/u	0	0
EOF
	mount /var/lib/clusterctrl/nfs/p$p_num/boot
	sed -i "s/180.1/180.$p_num/g" /var/lib/clusterctrl/nfs/p$p_num/boot/cmdline.txt
	sed -i "s/p1/p$p_num/g" /var/lib/clusterctrl/nfs/p$p_num/boot/cmdline.txt
	echo "172.19.180.$p_num    p$p_num" >> /etc/hosts
done
