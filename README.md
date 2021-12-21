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

## Create local mirror of alpine linux packages
  Just copy alpine-mirror to /etc/cron.daily
  ```
  cp alpine-mirror /etc/cron.daily
  ```

## lbu commit
  At the moment, no nfs mount yet. You can still backup using ssh from master
  
  ```
  ssh root@p1 "lbu pkg -" > /var/lib/clusterctrl/nfs/p1/p1.apkovl.tar.gz
  ```

## TODO
  1. Remove hard coded version
  2. Better overlay files, like adding nfs-utils package so lbu commit writes back to nfs
  3. Switch to dropbear, and use ssh-keygen for ssh authentication
  4. install proper packages and actually do something useful

