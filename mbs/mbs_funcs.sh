mbs_func_print_log()
{
    MSG_=$1
    echo $MSG_ >> $MBS_LOG
}

mbs_func_err_reboot()
{
    MSG_=$1
    KEEP_=$2

    echo $MSG_ >> $MBS_LOG
    echo $MSG_ > $ERR_MSG
    if [ -z $KEEP_ ]; then
        mv $MBS_CONF $MBS_CONF.keep
    fi
    sync
    sync
    sync

    umount /xdata
    reboot recovery
}

mbs_func_set_feature_aosp()
{
    ROM_TYPE_=$1

    mount -t proc proc /proc
    echo $ROM_TYPE_ > /proc/sys/kernel/feature_aosp
    umount /proc
}

mbs_func_extract_files()
{
    SRC_DIR_=$1
    LIST_FILE_=$2

    for FILE_ in `egrep -v '(^#|^$)' $LIST_FILE_`; do
        cp -a $SRC_DIR_$FILE_ $FILE_
        mbs_func_print_log "cp $SRC_DIR_$FILE_ $FILE_"
    done
}

mbs_func_generate_conf()
{
    CONF_=$1

    echo "mbs.boot.rom=0" > $CONF_
    echo "mbs.rom0.label=--" >> $CONF_
    echo "mbs.rom0.system.part=$MBS_BLKDEV_FACTORYFS" >> $CONF_
    echo "mbs.rom0.data.part=$MBS_BLKDEV_DATA" >> $CONF_
    echo "mbs.rom1.label=--"  >> $CONF_
    echo "mbs.rom0.data.path=/data0" >> $CONF_
    echo "mbs.rom1.system.part=$MBS_BLKDEV_HIDDEN" >> $CONF_
    echo "mbs.rom1.data.part=$MBS_BLKDEV_DATA" >> $CONF_
    echo "mbs.rom1.data.path=/data1" >> $CONF_
}

mbs_func_check_partition()
{
    PART_=$1
    IMG_=$2

    case $PART_ in
        "$MBS_BLKDEV_ZIMAGE" )    return 0 ;;
        "$MBS_BLKDEV_FACTORYFS" ) return 0 ;;
        "$MBS_BLKDEV_DATA" )      return 0 ;;
        "$MBS_BLKDEV_HIDDEN")     return 0 ;;
        "$MBS_BLKDEV_EMMC2" )     return 0 ;;
        "$MBS_BLKDEV_EMMC3" )     return 0 ;;
        "$MBS_BLKDEV_SDCARD" )    echo "vfat part" ;;
        "$MBS_BLKDEV_EMMC1" )     echo "vfat part" ;;
        *) mbs_func_err_reboot "$1 is invalid part" ;;
    esac

    if [ -z $IMG_ ]; then
        mbs_func_err_reboot "no img detect!"
    fi

    return 0
}

mbs_func_detect_rom_vendor()
{
    SYS_PATH_=$1

    if [ -f $SYS_PATH_/framework/twframework.jar ]; then
        if [ -f $SYS_PATH_/framework/framework-miui.jar ]; then
            echo miui
        else
            echo samsung
        fi
    else
        SDK_VER_=`grep ro\.build\.version\.sdk $SYS_PATH_/build.prop | cut -d'=' -f2`
        if [ "$SDK_VER_" = '15' ]; then
            echo aosp-ics
        else
            echo aosp-jb
        fi
    fi
}

mbs_func_get_low_power_mode()
{
    mount -t sysfs sysfs /sys
    MODE_=`cat /sys/class/power_supply/battery/batt_lp_charging`
    umount /sys
    echo $MODE_
}

mbs_func_get_recovery_mode()
{
    mount -t proc proc /proc
    MODE_=`grep -c bootmode=2 /proc/cmdline`
    umount /proc
    echo $MODE_
}

mbs_func_get_labeles()
{
    for i in $LOOP_CNT; do
		rom_data_part_=`grep mbs\.rom$i\.data\.part $MBS_CONF | cut -d'=' -f2`
		rom_data_path_=`grep mbs\.rom$i\.data\.path $MBS_CONF | cut -d'=' -f2`
		rom_sys_part_=`grep mbs\.rom$i\.system\.part $MBS_CONF | cut -d'=' -f2`

		if [ ! -z "$rom_data_part_" ] && [ ! -z "$rom_data_path_" ] && [ ! -z "$rom_sys_part_" ]; then
			rom_label_=`grep mbs\.rom$i\.label $MBS_CONF | cut -d'=' -f2`
			if [ -z "$rom_label_" ]; then
				rom_label_="none"
			fi
			echo "$rom_label_" | sed -e s/"[\\/:*?\"<>|]"/./g > $MBS_STAT_PATH/rom$i
		fi
    done
}

mbs_func_cleanup_sbin()
{
    rm /sbin/dedupe
    rm /sbin/dump_image
    rm /sbin/edify
    rm /sbin/erase_image
    rm /sbin/flash_image
    rm /sbin/getprop
    rm /sbin/minizip
    rm /sbin/nandroid
    rm /sbin/setprop
    rm /sbin/unyaffs
    rm /sbin/volume
}

