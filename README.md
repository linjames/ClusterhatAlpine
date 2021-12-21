# ClusterhatAlpine
  Build Alpine bootable image for Clusterhat

## Instructions
  Starts with either cbridge or cnat image from https://clusterctrl.com/setup-software
  
  Do your regular setup, like raspi-config and apt-get --allow-releaseinfo-change update && apt-get dist-upgrade

```
sudo -s
cd
git clone https://github.com/linjames/ClusterhatAlpine
cd ClusterhatAlpine
./build.sh
```
## lbu commit
  At the moment, no nfs mount yet. You can still backup using ssh from master
  
  ```
  ssh root@p1 "lbu pkg -" > /var/lib/clusterctrl/nfs/p1/p1.apkovl.tar.gz
  ```

## TODO
  1. Better overlay files, like adding nfs-utils package so lbu commit writes back to nfs
  2. Switch to dropbear, and use ssh-keygen for ssh authentication
  3. install proper packages and actually do something 

