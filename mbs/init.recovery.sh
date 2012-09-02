#!/sbin/busybox sh

. /mbs/mbs_funcs.sh

rom_sys_part=$MBS_BLKDEV_FACTORYFS
rom_data_part=$MBS_BLKDEV_DATA

func_set_feature_aosp $MBS_ROM_TYPE_AOSP

cp /mbs/recovery/default.prop /

sys_part_sed=`echo $rom_sys_part | sed -e 's/\//\\\\\\//g'`
sed -e "s/@MBS_MOUNT_SYSTEM/mount ext4 $sys_part_sed \/system wait rw/g" /mbs/recovery/recovery.rc.sed > /recovery.rc

