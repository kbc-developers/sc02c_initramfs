#!/sbin/busybox sh

. /mbs/mbs_const
. /mbs/mbs_funcs.sh

rom_sys_path=/mbs/mnt/system
rom_data_path=/mbs/mnt/data

rom_sys_part=$MBS_BLKDEV_FACTORYFS
rom_data_part=$MBS_BLKDEV_DATA

mount -t ext4 $MBS_BLKDEV_FACTORYFS $rom_sys_path
mount -t ext4 $MBS_BLKDEV_DATA $rom_data_path

export MBS_LOG=$rom_data_path/mbs.log
boot_date=`date`
echo "boot start single mode: $boot_date" > $MBS_LOG

# check rom vendor
rom_vender=`mbs_func_detect_rom_vendor $rom_sys_path`
sh /mbs/setup_rom.sh $rom_vender $rom_sys_path $rom_data_path

# Set TweakGS2 properties
sh /mbs/setup_tgs2.sh $rom_data_path

# create init.smdk4210.rc
mbs_func_make_init_rc

# create init.rc
mv /init.rc.sed /init.rc

umount $rom_sys_path
umount $rom_data_path

