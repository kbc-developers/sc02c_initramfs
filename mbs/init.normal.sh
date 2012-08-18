#!/sbin/busybox sh

rom_sys_path=/mbs/mnt/system
rom_data_path=/mbs/mnt/data

rom_sys_part="/dev/block/mmcblk0p9"
rom_data_part="/dev/block/mmcblk0p10"

mount -t ext4 /dev/block/mmcblk0p9 $rom_sys_path
mount -t ext4 /dev/block/mmcblk0p10 $rom_data_path

export MBS_LOG=$rom_data_path/mbs.log
echo "boot start : $BOOT_DATE" > $MBS_LOG




# check rom vendor
if [ -f $rom_sys_path/framework/twframework.jar ]; then
    if [ -f $rom_sys_path/framework/framework-miui.jar ]; then
        echo ROM is miui >> $MBS_LOG
        sh /mbs/init.miui.sh $rom_sys_path $rom_data_path
    else
    	echo ROM is samsung >> $MBS_LOG
        sh /mbs/init.samsung.sh $rom_sys_path $rom_data_path
    fi
else
    SDK_VER=`grep ro\.build\.version\.sdk $rom_sys_path/build.prop | cut -d'=' -f2`
    if [ "$SDK_VER" = '16' ]; then
    	echo ROM is aosp-jb >> $MBS_LOG
        sh /mbs/init.aosp-jb.sh $rom_sys_path $rom_data_path
    else
    	echo ROM is aosp-ics >> $MBS_LOG
        sh /mbs/init.aosp-ics.sh $rom_sys_path $rom_data_path
    fi
fi

# Set TweakGS2 properties
sh /mbs/init.tgs2.sh $rom_data_path

# create init.smdk4210.rc
#escape 
sys_part_sed=`echo $rom_sys_part | sed -e 's/\//\\\\\\//g'`
data_part_sed=`echo $rom_data_part | sed -e 's/\//\\\\\\//g'`

sed -e "s/@SYSTEM_DEV/$sys_part_sed/g" /init.smdk4210.rc.sed | sed -e "s/@DATA_DEV/$data_part_sed/g" > /init.smdk4210.rc
#mv /init.smdk4210.rc  $rom_data_path/init.smdk4210.rc
rm /init.smdk4210.rc.sed

# create init.rc
mv /init.rc.sed /init.rc

umount $rom_sys_path
umount $rom_data_path

