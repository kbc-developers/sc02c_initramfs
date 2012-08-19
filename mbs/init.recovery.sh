#!/sbin/busybox sh

rom_sys_part="/dev/block/mmcblk0p9"
rom_data_part="/dev/block/mmcblk0p10"


#set feature_aosp -> aosp
mount -t proc proc /proc
echo 1 > /proc/sys/kernel/feature_aosp
umount /proc

cp /mbs/recovery/default.prop /

sys_part_sed=`echo $rom_sys_part | sed -e 's/\//\\\\\\//g'`
sed -e "s/@MBS_MOUNT_SYSTEM/mount ext4 $sys_part_sed \/system wait rw/g" /mbs/recovery/recovery.rc.sed > /recovery.rc

