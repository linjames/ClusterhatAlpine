# ClusterhatAlpine
Build Alpine bootable image for Clusterhat
Get either cbridge or cnat image from https://clusterctrl.com/setup-software
Do you regular setup, like raspi-config and apt-get --allow-releaseinfo-change update && apt-get dist-upgrade

```
apt-get install git
git clone https://github.com/linjames/ClusterhatAlpine
cd ClusterhatAlpine
./build.sh
```

# TODO
  1. Better overlay files, like adding nfs-utils package so lbu commit writes back to nfs
  2. Switch to dropbear, and use ssh-keygen for ssh authentication
  3. install proper package and actually do something 

