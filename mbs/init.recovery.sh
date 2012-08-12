#!/sbin/busybox sh

#set feature_aosp -> aosp
mount -t proc proc /proc
echo 1 > /proc/sys/kernel/feature_aosp
umount /proc

cp /mbs/recovery/recovery.rc /
cp /mbs/recovery/default.prop /

