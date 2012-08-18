#!/sbin/busybox sh

#set feature_aosp -> samsung
mount -t proc proc /proc
echo 0 > /proc/sys/kernel/feature_aosp
umount /proc

# check bootanimation
if [ -f $2/local/bootanimation.zip ] || [ -f $1/media/bootanimation.zip ]; then
  BOOTANI_UID="root"
  # bootanimation wait one loop
  BOOTANIM_WAIT="setprop sys.bootanim_wait 1"
else
  BOOTANI_UID="graphics"
  BOOTANIM_WAIT=""
fi

# fix LPG Camera/movie
chmod 640 $1/lib/hw/hwcomposer.exynos4.so

# copy rc files
cp /mbs/samsung/default.prop /
#cp /mbs/samsung/init.smdk4210.rc /
cp /mbs/samsung/init.smdk4210.usb.rc /
cp /mbs/samsung/ueventd.rc /
cp /mbs/samsung/ueventd.smdk4210.rc /
cp /mbs/samsung/redbend_ua /sbin/
cp /mbs/samsung/lpm.rc /

# create init.rc
sed -e "s/@BOOTANI_UID/$BOOTANI_UID/g" /mbs/samsung/init.rc.sed | sed -e "s/@BOOTANIM_WAIT/$BOOTANIM_WAIT/g" > /init.rc.sed

# create init.smdk4210.rc
cp /mbs/samsung/init.smdk4210.rc /init.smdk4210.rc.sed


