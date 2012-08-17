#!/sbin/busybox sh

#set feature_aosp -> aosp
mount -t proc proc /proc
echo 1 > /proc/sys/kernel/feature_aosp
umount /proc

# copy rc files
cp /mbs/aosp-ics/default.prop /
#cp /mbs/aosp-ics/init.smdk4210.rc /
cp /mbs/aosp-ics/init.smdk4210.usb.rc /
cp /mbs/aosp-ics/ueventd.rc /
cp /mbs/aosp-ics/ueventd.smdk4210.rc /
cp /mbs/aosp-ics/lpm.rc /

# create init.rc
cp /mbs/aosp-ics/init.rc /

# create init.smdk4210.rc

#set here for single debug
$rom_sys_part="dev/block/mmcblk0p9"
$rom_data_part="dev/block/mmcblk0p10"
sed -e "s/@SYSTEM_DEV/$rom_sys_part/g" /mbs/aosp-ics/init.smdk4210.rc.sed | sed -e "s//@DATA_DEV/$rom_data_part/g" > /init.smdk4210.rc

