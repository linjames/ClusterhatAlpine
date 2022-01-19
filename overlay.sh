#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -C "clusterctrl" -q -f ~/.ssh/id_rsa -N ""
fi

mkdir -p /var/lib/clusterctrl/nfs/root/.ssh
cp ~/.ssh/id_rsa.pub /var/lib/clusterctrl/nfs/root/.ssh/authorized_keys
mkdir -p /var/lib/clusterctrl/nfs/home

mkdir /tmp/apkovl
cd /tmp/apkovl
mkdir -p etc/network
cat << EOF > etc/network/interfaces
auto lo
iface lo inet loopback

auto usb0
iface usb0 inet dhcp
EOF

mkdir -p etc/runlevels/default
ln -s /etc/init.d/dropbear etc/runlevels/default/dropbear
ln -s /etc/init.d/ntpd etc/runlevels/default/ntpd
ln -s /etc/init.d/nfsmount etc/runlevels/default/nfsmount
mkdir -p etc/apk
cat << EOF > etc/apk/world
alpine-base
dropbear
nfs-utils
openssl
screen
EOF
cat <<EOF > etc/fstab
/dev/cdrom      /media/cdrom    iso9660 noauto,ro 0 0
/dev/usbdisk    /media/usb      vfat    noauto,ro 0 0
172.19.180.254:/var/lib/clusterctrl/nfs/p1 /media/nfs nfs4 defaults 0 0
172.19.180.254:/var/lib/clusterctrl/nfs/root /root nfs4 defaults 0 0
172.19.180.254:/var/lib/clusterctrl/nfs/home /home nfs4 defaults 0 0
EOF
touch etc/.default_boot_services
#       d) update lbu commit config to include etc/init.d/hostname
#       e) zip it backup
cd /tmp

# 10. link lighttpd to the modloop
rm /var/www/html/modloop-rpi
rm /var/www/html/apks
rm /var/www/html/p{1,2,3,4}.apkovl.tar.gz
ln -s /var/lib/clusterctrl/nfs/boot/boot/modloop-rpi /var/www/html/modloop-rpi
ln -s /var/lib/clusterctrl/nfs/apks/ /var/www/html/apks

# 11 mount boot
cd /var/lib/clusterctrl/nfs

sed -i '/nfs\/p[1-4]\/boot/d' /etc/fstab
sed -i '/p[1-4]/d' /etc/hosts
umount /var/lib/clusterctrl/nfs/p{1,2,3,4}/boot
rm -rf /var/lib/clusterctrl/nfs/p{1,2,3,4}
mkdir -p /var/lib/clusterctrl/nfs/p{1,2,3,4}/{boot,u,w}

for p_num in 1 2 3 4
do
        cat <<EOF >> /etc/fstab
overlayfs       /var/lib/clusterctrl/nfs/p$p_num/boot   overlay         lowerdir=/var/lib/clusterctrl/nfs/boot,workdir=/var/lib/clusterctrl/nfs/p$p_num/w,upperdir=/var/lib/clusterctrl/nfs/p$p_num/u   0       0
EOF
        mount /var/lib/clusterctrl/nfs/p$p_num/boot
        sed -i "s/180.1/180.$p_num/g" /var/lib/clusterctrl/nfs/p$p_num/boot/cmdline.txt
        sed -i "s/p1/p$p_num/g" /var/lib/clusterctrl/nfs/p$p_num/boot/cmdline.txt
        echo "172.19.180.$p_num    p$p_num" >> /etc/hosts
	sed -i "s/p1/p$p_num/g" /tmp/apkovl/etc/fstab
	echo p$p_num > /tmp/apkovl/etc/hostname
	tar -czf /var/lib/clusterctrl/nfs/p$p_num/p$p_num.apkovl.tar.gz -C /tmp/apkovl .
	ln -s /var/lib/clusterctrl/nfs/p$p_num/p$p_num.apkovl.tar.gz /var/www/html/p$p_num.apkovl.tar.gz
	sed -i "s/p$p_num/p1/g" /tmp/apkovl/etc/fstab
done

#       f) cleanup
rm -rf /tmp/apkovl


