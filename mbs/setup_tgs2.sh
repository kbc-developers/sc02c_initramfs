#!/sbin/busybox sh

PROP_PATH=$1/tweakgs2.prop

USB_CONFIG=`grep ro\.sys\.usb\.config $PROP_PATH | cut -d'=' -f2`
if [ -n "$USB_CONFIG" ]; then
    setprop persist.sys.usb.config $USB_CONFIG
else
    setprop persist.sys.usb.config mtp,adb
fi

BOOT_SND=`grep audioflinger\.bootsnd $PROP_PATH | cut -d'=' -f2`
if [ "$BOOT_SND" = '1' ]; then
    setprop audioflinger.bootsnd 1
else
    setprop audioflinger.bootsnd 0
fi

CAMERA_SND=`grep ro\.camera\.sound\.forced $PROP_PATH | cut -d'=' -f2`
if [ "$CAMERA_SND" = '1' ]; then
    setprop ro.camera.sound.forced 1
else
    setprop ro.camera.sound.forced 0
fi

LCD_DENSITY=`grep ro\.sf\.lcd_density $PROP_PATH | cut -d'=' -f2`
if [ -n "$LCD_DENSITY" ]; then
    setprop ro.sf.lcd_density $LCD_DENSITY
fi

LOGGER=`grep ro\.tgs2\.logger $PROP_PATH | cut -d'=' -f2`
if [ "$LOGGER" = '1' ] || [ -z "$LOGGER" ] ; then
    insmod /lib/modules/logger.ko
fi

CIFS=`grep ro\.tgs2\.cifs $PROP_PATH | cut -d'=' -f2`
if [ "$CIFS" = '1' ]; then
    insmod /lib/modules/cifs.ko
fi

NTFS=`grep ro\.tgs2\.ntfs $PROP_PATH | cut -d'=' -f2`
if [ "$NTFS" = '1' ]; then
    insmod /lib/modules/ntfs.ko
fi

J4FS=`grep ro\.tgs2\.j4fs $PROP_PATH | cut -d'=' -f2`
if [ "$J4FS" = '1' ]; then
    insmod /lib/modules/j4fs.ko
fi

MUSIC_VOL_STEPS=`grep ro\.tweak\.music_vol_steps $PROP_PATH | cut -d'=' -f2`
if [ -n "$MUSIC_VOL_STEPS" ]; then
    setprop ro.tweak.music_vol_steps $MUSIC_VOL_STEPS
fi

SCROLLING_CACHE=`grep ro\.tweak\.scrolling_cache $PROP_PATH | cut -d'=' -f2`
if [ "$SCROLLING_CACHE" = '1' ]; then
    setprop ro.tweak.scrolling_cache 1
else
    setprop ro.tweak.scrolling_cache 0
fi

