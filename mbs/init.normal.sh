#!/sbin/busybox sh

rom_sys_path=/mbs/mnt/system
ROM_DATA_PATH=/mbs/mnt/data

mount -t ext4 /dev/block/mmcblk0p9 $rom_sys_path
mount -t ext4 /dev/block/mmcblk0p10 $ROM_DATA_PATH

export MBS_LOG=$ROM_DATA_PATH/mbs.log
echo "boot start : $BOOT_DATE" > $MBS_LOG


# check rom vendor
if [ -f $rom_sys_path/framework/twframework.jar ]; then
    if [ -f $rom_sys_path/framework/framework-miui.jar ]; then
        echo ROM is miui >> $MBS_LOG
        sh /mbs/init.miui.sh $rom_sys_path $ROM_DATA_PATH
    else
    	echo ROM is samsung >> $MBS_LOG
        sh /mbs/init.samsung.sh $rom_sys_path $ROM_DATA_PATH
    fi
else
    SDK_VER=`grep ro\.build\.version\.sdk $rom_sys_path/build.prop | cut -d'=' -f2`
    if [ "$SDK_VER" = '16' ]; then
    	echo ROM is aosp-jb >> $MBS_LOG
        sh /mbs/init.aosp-jb.sh $rom_sys_path $ROM_DATA_PATH
    else
    	echo ROM is aosp-ics >> $MBS_LOG
        sh /mbs/init.aosp-ics.sh $rom_sys_path $ROM_DATA_PATH
    fi
fi

# Set TweakGS2 properties
sh /mbs/init.tgs2.sh $ROM_DATA_PATH

umount $rom_sys_path
umount $ROM_DATA_PATH

