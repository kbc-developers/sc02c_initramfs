#!/sbin/busybox sh

#$1:rom_sys\path $2:rom_data_path

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
cp /mbs/aosp-ics/init.rc /init.rc.sed

# create init.smdk4210.rc
cp /mbs/aosp-ics/init.smdk4210.rc.sed /
