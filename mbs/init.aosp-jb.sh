#!/sbin/busybox sh

#set feature_aosp -> aosp
mount -t proc proc /proc
echo 1 > /proc/sys/kernel/feature_aosp
umount /proc

echo aosp-jb.sh is called >> $MBS_LOG

# copy rc files
cp /mbs/aosp-jb/default.prop /
#cp /mbs/aosp-jb/init.smdk4210.rc /
cp /mbs/aosp-jb/init.smdk4210.usb.rc /
cp /mbs/aosp-jb/init.trace.rc /
cp /mbs/aosp-jb/init.usb.rc /
cp /mbs/aosp-jb/ueventd.rc /
cp /mbs/aosp-jb/ueventd.smdk4210.rc /
cp /mbs/aosp-jb/lpm.rc /

# copy bin files
cp /mbs/aosp-jb/adbd /sbin/
cp /mbs/aosp-jb/bootanimation /sbin/
# create init.rc
cp /mbs/aosp-jb/init.rc /

# create init.smdk4210.rc

#set here for single debug
rom_sys_part="/dev/block/mmcblk0p9"
rom_data_part="/dev/block/mmcblk0p10"

#escape 
sys_part_sed=`echo $rom_sys_part | sed -e 's/\//\\\\\\//g'`
data_part_sed=`echo $rom_data_part | sed -e 's/\//\\\\\\//g'`

sed -e "s/@SYSTEM_DEV/$sys_part_sed/g" /mbs/aosp-jb/init.smdk4210.rc.sed | sed -e "s/@DATA_DEV/$data_part_sed/g" > /init.smdk4210.rc

cp /init.smdk4210.rc $2/init.smdk4210.rc

