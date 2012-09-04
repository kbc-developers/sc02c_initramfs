#!/sbin/busybox sh

. /mbs/mbs_const
. /mbs/mbs_funcs.sh

export MBS_CONF="/mbs/mnt/data/mbs.conf"

BOOT_MODE=$1

func_init_single()
{
    SYS_PART=`echo $MBS_BLKDEV_FACTORYFS | sed -e 's/\//\\\\\\//g'`
    sed -e "s/@MBS_MOUNT_SYSTEM/mount ext4 $SYS_PART \/system wait rw/g" /init.rc.sed > /init.rc
    rm /init.rc.sed
}

func_init_multi()
{
    # create stat dir
    mkdir /mbs/stat

    # parse mbs.conf
    mkdir -p /mbs/mnt/data
    mount -t ext4 $MBS_BLKDEV_DATA /mbs/mnt/data

    # move errmsg
    mv /mbs/mnt/data/mbs.err /mbs/stat/mbs.err

    if [ ! -s $MBS_CONF ]; then
        mbs_func_generate_conf $MBS_CONF
    fi

    ret=`grep mbs\.boot\.rom $MBS_CONF | cut -d'=' -f2`
    if [ -z "$ret" ]; then
        rom_id=0
    else
        rom_id=$ret
    fi

    rom_system_part=`grep mbs\.rom$rom_id\.system\.part $MBS_CONF | cut -d'=' -f2`
    rom_system_img=`grep mbs\.rom$rom_id\.system\.img $MBS_CONF | cut -d'=' -f2`
    rom_data_part=`grep mbs\.rom$rom_id\.data\.part $MBS_CONF | cut -d'=' -f2`
    rom_data_img=`grep mbs\.rom$rom_id\.data\.img $MBS_CONF | cut -d'=' -f2`
    rom_data_path=`grep mbs\.rom$rom_id\.data\.path $MBS_CONF | cut -d'=' -f2`

    umount /mbs/mnt/data

    mbs_func_check_partition $rom_system_part $rom_system_img
    mbs_func_check_partition $rom_data_part $rom_data_img

    # check error
    if [ -z "$rom_system_part" ]; then
        rom_system_part="$MBS_BLKDEV_FACTORYFS"
        rom_system_img=""
    fi
    if [ -z "$rom_data_part" ]; then
        rom_data_part="$MBS_BLKDEV_DATA"
        rom_data_img=""
    fi

    # create fstab
    PARTITION_FORMAT=ext4

    # add /xdata entry
    echo "/xdata        ext4        $MBS_BLKDEV_DATA" >> /misc/recovery.fstab

    # add /system entry
    if [ -z "$rom_system_img" ]; then
        MBS_MOUNT_SYSTEM=`echo $rom_system_part | sed -e "s/\//\\\\\\\\\//g"`
        sed -e "s/@MBS_MOUNT_SYSTEM/mount ext4 $MBS_MOUNT_SYSTEM \/system wait rw/g" /init.rc.sed > /init.rc
        rm /init.rc.sed

        echo "/system        ext4        $rom_system_part" >> /misc/recovery.fstab

        echo $rom_system_part > /mbs/stat/system_device
    else
        if [ "$rom_system_part" = "$MBS_BLKDEV_SDCARD" ] || [ "$rom_system_part" = "$MBS_BLKDEV_EMMC1" ]; then
            PARTITION_FORMAT=vfat
    fi

    mkdir -p /mbs/mnt/sys_img
    mount -t $PARTITION_FORMAT $rom_system_part /mbs/mnt/sys_img
    mbs_mount_system=`echo loop@/mbs/mnt/rom$rom_id/sys_img$rom_system_img | sed -e "s/\//\\\\\\\\\//g"`
    sed -e "s/@MBS_MOUNT_SYSTEM/mount ext4 $mbs_mount_system \/system wait rw/g" /init.rc.sed > /init.rc
    rm /init.rc.sed

    echo "/system        ext4        /mbs/mnt/sys_img$rom_system_img        loop" >> /misc/recovery.fstab
    echo /mbs/mnt/sys_img$rom_system_img > /mbs/stat/system_device
    fi

    # add data_dev entry
    if [ -z "$rom_data_img" ]; then
        echo "/data_dev    ext4        $rom_data_part" >> /misc/recovery.fstab

        mkdir -p /data_dev
        if [ ! -z $rom_data_path ] || [ ! "$rom_data_path" = "/" ];then
            mount -t ext4 $rom_data_part /data_dev 
            mkdir -p /data_dev$rom_data_path
            umount /data_dev
        fi

        ln -s /data_dev$rom_data_path /data
    else
        if [ "$rom_data_part" = "$MBS_BLKDEV_SDCARD" ] || [ "$rom_data_part" = "$MBS_BLKDEV_EMMC1" ]; then
            PARTITION_FORMAT=vfat
        fi
        mkdir -p /mbs/mnt/data_img
        mkdir -p /data_dev
        mount -t $PARTITION_FORMAT $rom_data_part /mbs/mnt/data_img

        if [ ! -z $rom_data_path ] || [ ! "$rom_data_path" = "/" ];then
            mount -t ext4 -o rw,loop /mbs/mnt/data_img$rom_data_img /data_dev 
            mkdir -p /data_dev$rom_data_path
            umount /data_dev
        fi

        ln -s /data_dev$rom_data_path /data
        echo "/data_dev    ext4        /mbs/mnt/data_img$rom_data_img        loop" >> /misc/recovery.fstab
    fi

    #put current boot rom nuber info
    echo $rom_id > /mbs/stat/bootrom
}


if [ "$BOOT_MODE" = "$MBS_BOOT_MODE_MULTI" ]; then
    sh /mbs/setup_rom.sh recovery-multi
    func_init_multi
else
    sh /mbs/setup_rom.sh recovery-single
    func_init_single
fi

