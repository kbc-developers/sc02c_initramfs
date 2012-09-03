
msb_func_err_reboot()
{
    MSG=$1

    echo $MSG >> $MBS_LOG
    echo $MSG > $ERR_MSG
    mv $MBS_CONF $MBS_CONF.keep
    sync
    sync
    sync

    umount /xdata
    reboot recovery
}

msb_func_set_feature_aosp()
{
    ROM_TYPE=$1

    mount -t proc proc /proc
    echo $ROM_TYPE > /proc/sys/kernel/feature_aosp
    umount /proc
}

msb_func_extract_files()
{
    SRC_DIR=$1
    LIST_FILE=$2

    for FILE in `egrep -v '(^#|^$)' $LIST_FILE`; do
        cp $SRC_DIR$FILE $FILE
        echo "cp $SRC_DIR$FILE $FILE" >> $MBS_LOG
    done
}

mbs_func_generate_conf()
{
    CONF=$1

    echo "mbs.boot.rom=0" > $CONF
    echo "mbs.rom0.system.part=$MBS_BLKDEV_FACTORYFS" >> $CONF
    echo "mbs.rom0.data.part=$MBS_BLKDEV_DATA" >> $CONF
    echo "mbs.rom0.data.path=/data0" >> $CONF
    echo "mbs.rom1.system.part=$MBS_BLKDEV_HIDDEN" >> $CONF
    echo "mbs.rom1.data.part=$MBS_BLKDEV_DATA" >> $CONF
    echo "mbs.rom1.data.path=/data1" >> $CONF
}

mbs_func_check_partition()
{
    PART=$1
    IMG=$2

    case $PART in
        "$MBS_BLKDEV_ZIMAGE" )    return 0 ;;
        "$MBS_BLKDEV_FACTORYFS" ) return 0 ;;
        "$MBS_BLKDEV_DATA" )      return 0 ;;
        "$MBS_BLKDEV_HIDDEN")     return 0 ;;
        "$MBS_BLKDEV_EMMC2" )     return 0 ;;
        "$MBS_BLKDEV_EMMC3" )     return 0 ;;
        "$MBS_BLKDEV_SDCARD" )    echo "vfat part" ;;
        "$MBS_BLKDEV_EMMC1" )     echo "vfat part" ;;
        *) msb_func_err_reboot "$1 is invalid part" ;;
    esac

    if [ -z $IMG ]; then
        msb_func_err_reboot "no img detect!"
    fi

    return 0
}

mbs_func_detect_rom_vendor()
{
    SYS_PATH=$1

    if [ -f $SYS_PATH/framework/twframework.jar ]; then
        if [ -f $SYS_PATH/framework/framework-miui.jar ]; then
            echo miui
        else
            echo samsung
        fi
    else
        SDK_VER=`grep ro\.build\.version\.sdk $SYS_PATH/build.prop | cut -d'=' -f2`
        if [ "$SDK_VER" = '16' ]; then
            echo aosp-jb
        else
            echo aosp-ics
        fi
    fi
}

mbs_func_get_low_power_mode()
{
    mount -t sysfs sysfs /sys
    MODE=`cat /sys/class/power_supply/battery/batt_lp_charging`
    umount /sys
    echo $MODE
}

mbs_func_get_recovery_mode()
{
    mount -t proc proc /proc
    MODE=`grep -c bootmode=2 /proc/cmdline`
    umount /proc
    echo $MODE
}

