# fdisk -l /dev/sde
Disk /dev/sde: 29.73 GiB, 31921799168 bytes, 62347264 sectors
Disk model: STORAGE DEVICE  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x6b666df0

Device     Boot  Start      End  Sectors  Size Id Type
/dev/sde1  *      2048   309247   307200  150M  c W95 FAT32 (LBA)
/dev/sde2       309248 62333951 62024704 29.6G 83 Linux

firmware_version=1.20240529
curl -L https://github.com/raspberrypi/firmware/archive/refs/tags/"${firmware_version}".tar.gz --output firmware-"${firmware_version}".tar.gz
tar xfz firmware-"${firmware_version}".tar.gz

cp -rdp firmware-"${firmware_version}"/boot/* firmware-"${firmware_version}"/extra/* /boot/
cp -rdp firmware-"${firmware_version}"/modules/* /lib/modules/

# install /boot
cp -rdp firmware-"${firmware_version}"/boot/* /mnt/boot/

# install gentoo
cd /mnt/root && tar xfJ ~/rp64/stage3-arm64-openrc-20221106T214655Z.tar.xz && cp -rdp ~/rp64/firmware-1.20221104/opt/* opt/
/lib/firmware
# rsync -av /etc/wpa_supplicant/ k8s-2-int:/etc/wpa_supplicant
# rsync -av /usr/sbin/wpa_supplicant  k8s-2-int:/usr/sbin/wpa_supplicant
# rsync -av  /usr/lib64/libnl-3.so.200* k8s-2-int:/usr/lib64
# rsync -av  /usr/lib64/libnl-genl-3.so.200* k8s-2-int:/usr/lib64
# rsync -av  /usr/bin/wpa_cli k8s-2-int:/usr/bin/wpa_cli


# edit
etc/hosts
etc/conf.d/hostname
etc/conf.d/net
/mnt/boot/boot/cmdline
/mnt/boot/config.txt

# plus ...
(cd etc/init.d/ && ln -s net.lo net.end0
mkdir root/.ssh && chmod 700 root/.ssh
root/.ssh/authorized_keys
ln -s /etc/init.d/sshd etc/runlevels/default/sshd



