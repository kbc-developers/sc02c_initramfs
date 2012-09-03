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
#escape 
sys_part_sed=`echo $rom_sys_part | sed -e 's/\//\\\\\\//g'`
data_part_sed=`echo $rom_data_part | sed -e 's/\//\\\\\\//g'`

sed -e "s/@SYSTEM_DEV/$sys_part_sed/g" /init.smdk4210.rc.sed | sed -e "s/@DATA_DEV/$data_part_sed/g" | sed -e "s/@MBS_COMMENT//g" > /init.smdk4210.rc
#mv /init.smdk4210.rc  $rom_data_path/init.smdk4210.rc
rm /init.smdk4210.rc.sed

# create init.rc
mv /init.rc.sed /init.rc

umount $rom_sys_path
umount $rom_data_path

