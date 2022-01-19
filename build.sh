#! /usr/bin/bash
# save current directory
SCRIPTPATH=$(dirname "$0")

cd /tmp
# 0. for my server
# apt-get install -y tmux sysstat ifstat conspy

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
if [ -d ../apks ]; then
	rm -rf apks
else
	mv apks ../
fi
# 6. update cmdline.txt
cat <<EOF > cmdline.txt
modules=loop,squashfs,u_ether,u_serial console=ttyAMA0,115200 ip=172.19.180.1::172.19.180.254:255.255.255.0:p1:usb0.10:static modloop=http://172.19.180.254/modloop-rpi alpine_repo=http://172.19.180.254/apks apkovl=http://172.19.180.254/p1.apkovl.tar.gz
EOF

# 7. update config.txt [remove last line, add 3 lines]
if [ ! -f config.old ]; then
	mv config.txt config.old
fi
head -n -1 config.old > config.txt
cat <<EOF >> config.txt
dtoverlay=dwc2,dr_mode=peripheral
enable_uart=1
gpu_mem=16
EOF

$SCRIPTPATH/initramfs.sh
$SCRIPTPATH/overlay.sh

