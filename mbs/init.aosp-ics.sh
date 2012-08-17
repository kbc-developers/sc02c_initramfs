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
rom_sys_part="/dev/block/mmcblk0p9"
rom_data_part="/dev/block/mmcblk0p10"

#escape 
sys_part_sed=`echo $rom_sys_part | sed -e 's/\//\\\\\\//g'`
data_part_sed=`echo $rom_data_part | sed -e 's/\//\\\\\\//g'`

sed -e "s/@SYSTEM_DEV/$sys_part_sed/g" /mbs/aosp-ics/init.smdk4210.rc.sed | sed -e "s/@DATA_DEV/$data_part_sed/g" > /init.smdk4210.rc
