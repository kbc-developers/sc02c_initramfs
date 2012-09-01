#!/sbin/busybox sh

#$1:rom_sys\path $2:rom_data_path

#set feature_aosp -> aosp
mount -t proc proc /proc
echo 1 > /proc/sys/kernel/feature_aosp
umount /proc

echo aosp-jb.sh is called >> $MBS_LOG

# copy rc files
cp /mbs/aosp-jb/default.prop /
cp /mbs/aosp-jb/init.smdk4210.usb.rc /
cp /mbs/aosp-jb/init.trace.rc /
cp /mbs/aosp-jb/init.usb.rc /
cp /mbs/aosp-jb/ueventd.rc /
cp /mbs/aosp-jb/ueventd.smdk4210.rc /
cp /mbs/aosp-jb/lpm.rc /

# copy bin files
cp /mbs/aosp-jb/init /init
cp /mbs/aosp-jb/charger /charger
cp /mbs/aosp-jb/sbin/adbd /sbin/
cp /mbs/aosp-jb/sbin/bootanimation /sbin/

# create init.rc
cp /mbs/aosp-jb/init.rc /init.rc.sed

# create init.smdk4210.rc
cp /mbs/aosp-jb/init.smdk4210.rc.sed /

