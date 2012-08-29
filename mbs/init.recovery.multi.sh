#!/sbin/busybox sh

export MBS_CONF="/mbs/mnt/data/mbs.conf"

#set feature_aosp -> aosp
mount -t proc proc /proc
echo 1 > /proc/sys/kernel/feature_aosp
umount /proc
#------------------------------------------------------
#foce ROM0 boot setting
#   $1 xxxx.part value
#   $2 xxxx.img value
#------------------------------------------------------
func_make_conf()
{
    echo "mbs.boot.rom=0" > $MBS_CONF
    echo "mbs.rom0.system.part=$DEV_BLOCK_FACTORYFS" >> $MBS_CONF
    echo "mbs.rom0.data.part=$DEV_BLOCK_DATA" >> $MBS_CONF
    echo "mbs.rom0.data.path=/data0" >> $MBS_CONF
    echo "mbs.rom1.system.part=$DEV_BLOCK_HIDDEN" >> $MBS_CONF
    echo "mbs.rom1.data.part=$DEV_BLOCK_DATA" >> $MBS_CONF
    echo "mbs.rom1.data.path=/data1" >> $MBS_CONF
}
#------------------------------------------------------
#foce ROM0 boot setting
#	$1: error msg
#------------------------------------------------------
func_error()
{
	mv $MBS_CONF $MBS_CONF.old
	func_make_conf
}
#------------------------------------------------------
# check patation
#   $1 xxxx.part value
#   $2 xxxx.img value
#------------------------------------------------------
func_check_part()
{
	case $1 in
		"$DEV_BLOCK_ZIMAGE"    )    return 0 ;;
		"$DEV_BLOCK_FACTORYFS" )    return 0 ;;
		"$DEV_BLOCK_DATA"      )    return 0 ;;
		"$DEV_BLOCK_HIDDEN"    )    return 0 ;;
		"$DEV_BLOCK_EMMC2"     )    return 0 ;;
		"$DEV_BLOCK_EMMC3"     )    return 0 ;;
		"$DEV_BLOCK_SDCARD"    )    echo "vfat part" ;;
		"$DEV_BLOCK_EMMC1"     )    echo "vfat part" ;;
	    *)       func_error "$1 is invalid part" ;;
	esac

	if [ -z $2 ]; then
		func_error  "no img detect!"
	fi
	#echo "part is OK"
	return 0
}

#------------------------------------------------------
# Main Process
#------------------------------------------------------
    # build target multi
    cp /mbs/recovery/recovery.multi /sbin/recovery

    # create stat dir
    mkdir /mbs/stat

    # parse mbs.conf
    mkdir -p /mbs/mnt/data
    mount -t ext4 $DEV_BLOCK_DATA /mbs/mnt/data

    # move errmsg
    mv /mbs/mnt/data/mbs.err /mbs/stat/

    if [ ! -s $MBS_CONF ]; then
        func_make_conf
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

	func_check_part $rom_system_part $rom_system_img
	func_check_part $rom_data_part $rom_data_img

    # check error
    if [ -z "$rom_system_part" ]; then
        rom_system_part="$DEV_BLOCK_FACTORYFS"
        rom_system_img=""
    fi
    if [ -z "$rom_data_part" ]; then
        rom_data_part="$DEV_BLOCK_DATA"
        rom_data_img=""
    fi

    # create fstab
    PARTITION_FORMAT=ext4
    echo "/xdata		ext4		$DEV_BLOCK_DATA" >> /mbs/recovery/recovery.fstab
    if [ -z "$rom_system_img" ]; then
        MBS_MOUNT_SYSTEM=`echo $rom_system_part | sed -e "s/\//\\\\\\\\\//g"`
        sed -e "s/@MBS_MOUNT_SYSTEM/mount ext4 $MBS_MOUNT_SYSTEM \/system wait rw/g" /mbs/recovery/recovery.rc.sed > /recovery.rc

        echo "/system		ext4		$rom_system_part" >> /mbs/recovery/recovery.fstab
        echo $rom_system_part > /mbs/stat/system_device
    else
        if [ "$rom_system_part" = "$DEV_BLOCK_SDCARD" ] || [ "$rom_system_part" = "$DEV_BLOCK_EMMC1" ]; then
            PARTITION_FORMAT=vfat
        fi
        mkdir -p /mbs/mnt/sys_img
        mount -t $PARTITION_FORMAT $rom_system_part /mbs/mnt/sys_img
        mbs_mount_system=`echo loop@/mbs/mnt/rom$rom_id/sys_img$rom_system_img | sed -e "s/\//\\\\\\\\\//g"`
        sed -e "s/@MBS_MOUNT_SYSTEM/mount ext4 $mbs_mount_system \/system wait rw/g" /mbs/recovery/recovery.rc.sed > /recovery.rc

        echo "/system		ext4		/mbs/mnt/sys_img$rom_system_img		loop" >> /mbs/recovery/recovery.fstab
        echo /mbs/mnt/sys_img$rom_system_img > /mbs/stat/system_device
    fi

    if [ -z "$rom_data_img" ]; then
        echo "/data_dev	ext4		$rom_data_part" >> /mbs/recovery/recovery.fstab

        mkdir -p /data_dev

		if [ ! -z $rom_data_path ] || [ ! "$rom_data_path" = "/" ];then
			mount -t ext4 $rom_data_part /data_dev 
			mkdir -p /data_dev$rom_data_path
			umont /data_dev
		fi

        ln -s /data_dev$rom_data_path /data
    else
        if [ "$rom_data_part" = "$DEV_BLOCK_SDCARD" ] || [ "$rom_data_part" = "$DEV_BLOCK_EMMC1" ]; then
            PARTITION_FORMAT=vfat
        fi
        mkdir -p /mbs/mnt/data_img
        mkdir -p /data_dev
        mount -t $PARTITION_FORMAT $rom_data_part /mbs/mnt/data_img

		if [ ! -z $rom_data_path ] || [ ! "$rom_data_path" = "/" ];then
			mount -t ext4 -o rw,loop /mbs/mnt/data_img$rom_data_img /data_dev 
			mkdir -p /data_dev$rom_data_path
			umont /data_dev
		fi

        ln -s /data_dev$rom_data_path /data
        echo "/data_dev	ext4		/mbs/mnt/data_img$rom_data_img		loop" >> /mbs/recovery/recovery.fstab

    fi

    #put current boot rom nuber info
    echo $rom_id > /mbs/stat/bootrom


cp /mbs/recovery/recovery.fstab /misc/
cp /mbs/recovery/default.prop /
cp /mbs/recovery/updater.multi /mbs/recovery/updater
