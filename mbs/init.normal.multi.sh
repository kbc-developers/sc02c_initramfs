#!/sbin/busybox sh

. /mbs/mbs_const
. /mbs/mbs_funcs.sh

#set config
export MBS_LOG=/xdata/mbs.log
export MBS_LOG_1="/xdata/mbs.old1.log"
export MBS_LOG_2="/xdata/mbs.old2.log"
export MBS_CONF="/xdata/mbs.conf"
export ERR_MSG="/xdata/mbs.err"


export INIT_RC_DST=/init.rc
export INIT_RC_SRC=/init.rc.sed
export LOOP_CNT="0 1 2 3 4 5 6 7"
export RET=""

#note)script process is "main process" is 1st
#------------------------------------------------------
# mbs log init
#
#------------------------------------------------------
func_log_init()
{
    #log backup----------------
    if [ -f $MBS_LOG_1 ]; then
        mv $MBS_LOG_1 $MBS_LOG_2
    fi
    if [ -f $MBS_LOG ]; then
        mv $MBS_LOG $MBS_LOG_1
    fi
    #-------------------------
    boot_date=`date`
    echo "boot start mbs mode: $boot_date" > $MBS_LOG
}

#------------------------------------------------------
#init mbs dev mnt point
#    $1: loop cnt
#------------------------------------------------------
func_mbs_init()
{
    #err staus clear (no check exist)
    rm $ERR_MSG

    #patation,path infomation init
    if [ ! -f $MBS_CONF ]; then
        echo "$MBS_CONF is not exist" >> $MBS_LOG
        mbs_func_err_reboot "$MBS_CONF is not exist"
    fi

    #/system is synbolic link when multi boot.
    #rmdir /system
    #system is directory mount 2012/02/05
    mkdir /system
    chmod 755 /system
    
    #make mbs dev mnt point
    chmod 755 /mbs/mnt
    for i in $1; do
        mkdir /mbs/mnt/rom${i}
        mkdir /mbs/mnt/rom${i}/data_dev
        mkdir /mbs/mnt/rom${i}/data_img
        mkdir /mbs/mnt/rom${i}/sys_dev
        mkdir /mbs/mnt/rom${i}/sys_img

        chmod 755 /mbs/mnt/rom${i}
        chmod 755 /mbs/mnt/rom${i}/data_dev
        chmod 755 /mbs/mnt/rom${i}/data_img
        chmod 755 /mbs/mnt/rom${i}/sys_dev
        chmod 755 /mbs/mnt/rom${i}/sys_img
    done
}

#------------------------------------------------------
#create loopback device
#    $1:arg_mnt_base
#    $2:arg_img_part: partation
#    $3:arg_img_path:$rom_data_img
#    $4:arg_mnt_img: data_img / sys_img
#    $5:arg_mnt_loop: data_loop / sys_loop
#    $6:arg_dev_id; 20${id} /10${id}
#------------------------------------------------------
func_mbs_create_loop_dev()
{
    arg_mnt_base=$1
    arg_img_part=$2
    arg_img_path=$3
    arg_mnt_img=$4
    arg_mnt_loop=$5
    arg_dev_id=$6

    #mount img part device
    mnt_img=$arg_mnt_base/$arg_mnt_img
    img_path=$mnt_img$arg_img_path
    dev_loop=$arg_mnt_base/$arg_mnt_loop
    
    echo img_part=$arg_img_part >> $MBS_LOG
    echo mnt_img=$mnt_img >> $MBS_LOG
    echo img_path=$img_path >> $MBS_LOG
    echo dev_loop=$dev_loop >> $MBS_LOG
    
    fotmat=ext4

    dev=`echo  $arg_img_part | grep -o /dev/block/mmcblk.`


    if [ "$arg_img_part" = "$MBS_BLKDEV_SDCARD" ] || [ "$arg_img_part" = "$MBS_BLKDEV_EMMC1" ]; then
            fotmat=vfat
    fi
#format auto detect... dose not works..
#    echo dev=$dev >> $MBS_LOG
#    if [ "$dev" = "/dev/block/mmcblk0" ]; then
#        
#        if [ "$arg_img_part" = "$MBS_BLKDEV_DATA" ]; then
#            fotmat="vfat"
#        fi
#    else
#        fdisk -l $dev >> $MBS_LOG
#        res=`fdisk -l $dev | grep $arg_img_part | grep -o "Win95 FAT32"`
#        echo res=$res >> $MBS_LOG
#        if [ ! -z $res ]; then
#            fotmat="vfat"
#        fi
#    fi
    echo "fotmat=$fotmat" >> $MBS_LOG
    
    if [ "$fotmat" = 'vfat' ]; then
        mount -t $fotmat $arg_img_part $mnt_img
    else
        mount -t $fotmat $arg_img_part $mnt_img
    fi
    #echo `ls -l $mnt_img` >> $MBS_LOG
    # set loopback devce
    if [ -f $img_path ]; then
        echo create loop: $dev_loop >> $MBS_LOG
        mknod $dev_loop b 7 ${arg_dev_id}
        losetup $dev_loop $img_path
        export RET=$dev_loop
    else
        umount $mnt_img
        export RET=""
        echo "warning)$img_path is not exist" >> $MBS_LOG
    fi
}



#------------------------------------------------------
#mbs.conf anarisis & get infomation
#    no args
#    no check mbs.conf exist
#------------------------------------------------------
func_get_mbs_data_setting()
{
	arg_rom_id=$1
    # romX setting
    rom_data_part=`grep mbs\.rom$arg_rom_id\.data\.part $MBS_CONF | cut -d'=' -f2`
    rom_data_img=`grep mbs\.rom$arg_rom_id\.data\.img $MBS_CONF | cut -d'=' -f2`
    rom_data_path=`grep mbs\.rom$arg_rom_id\.data\.path $MBS_CONF | cut -d'=' -f2`

    if [ ! -z "$rom_data_part" ]; then
        mbs_func_check_partition $rom_data_part $rom_data_img

        mnt_base=/mbs/mnt/rom${arg_rom_id}
        mnt_dir=$mnt_base/data_dev

        if [ ! -z "$rom_data_img" ]; then
            func_mbs_create_loop_dev $mnt_base $rom_data_part $rom_data_img data_img data_loop 20${arg_rom_id}
            rom_data_part=$RET
            if [ -z "$rom_data_part" ]; then
                echo rom${arg_rom_id} image is not exist >> $MBS_LOG
            fi
        fi
        rom_data_path=$mnt_dir$rom_data_path
        rom_data_path=`echo $rom_data_path | sed -e "s/\/$//g"`

        eval export rom_data_part_$arg_rom_id=$rom_data_part
        eval export rom_data_img_$arg_rom_id=$rom_data_img
        eval export rom_data_path_$arg_rom_id=$rom_data_path
    fi
}

#------------------------------------------------------
#mbs.conf anarisis & get infomation
#    $1 = rom_id
#    no check mbs.conf exist
#------------------------------------------------------
func_get_mbs_system_setting()
{
    arg_rom_id=$1

    export rom_sys_part=`grep mbs\.rom$arg_rom_id\.system\.part $MBS_CONF | cut -d'=' -f2`
    export rom_sys_img=`grep mbs\.rom$arg_rom_id\.system\.img $MBS_CONF | cut -d'=' -f2`
    #export rom_sys_path=`grep mbs\.rom$arg_rom_id\.system\.path $MBS_CONF | cut -d'=' -f2`
    export rom_sys_path="/system"

    mbs_func_check_partition $rom_sys_part $rom_sys_img

    mnt_base=/mbs/mnt/rom${arg_rom_id}
    mnt_dir=$mnt_base/sys_dev
    if [ ! -z "$rom_sys_img" ]; then
        echo rom_sys_img :$rom_sys_img >> $MBS_LOG

        func_mbs_create_loop_dev $mnt_base $rom_sys_part $rom_sys_img sys_img sys_loop 10${arg_rom_id}
        rom_sys_part=$RET
    fi

    if [ -z "$rom_sys_part" ]; then
        echo rom${arg_rom_id} sys is invalid >> $MBS_LOG
        mbs_func_err_reboot "rom${arg_rom_id} sys is invalid"
    fi
}

#------------------------------------------------------
#mbs.conf anarisis & get infomation
#    $1 = rom_id
#    no check mbs.conf exist
#------------------------------------------------------
func_get_mbs_kernel_setting()
{
     arg_rom_id=$1
     # check kernel
#    KERNEL_PART=`grep mbs\.rom$rom_id\.kernel\.part $MBS_CONF | cut -d'=' -f2`
#    KERNEL_IMG=`grep mbs\.rom$rom_id\.kernel\.img $MBS_CONF | cut -d'=' -f2`
#    if [ ! -z $KERNEL_PART ];then
#        #kernel swich does not support for boot speed
#        func_check_part $KERNEL_PART $KERNEL_IMG
#        sh /mbs/init.kernel.sh $KERNEL_PART $KERNEL_IMG
#    fi
}
#------------------------------------------------------
#mbs.conf anarisis & get infomation
#    no args
#    no check mbs.conf exist
#------------------------------------------------------
func_get_mbs_info()
{
    # get boot rom number
    ret=`grep mbs\.boot\.rom $MBS_CONF | cut -d'=' -f2`
    if [ -e "$ret" ]; then
      rom_id=0
    else
      rom_id=$ret
    fi
    echo "rom_id : $rom_id" >> $MBS_LOG
    #----------------------------
    # set kernel
    #----------------------------
    #func_get_mbs_kernel_setting

    #----------------------------
    # set data
    #----------------------------
    echo "start of get data " >> $MBS_LOG
    for i in $LOOP_CNT; do
        echo "for:$i" >> $MBS_LOG
        func_get_mbs_data_setting $i
        #for Debug
        eval echo mbs.rom${i}.data.part=$"rom_data_part_"$i >> $MBS_LOG
        eval echo mbs.rom${i}.data.img=$"rom_data_img_"$i >> $MBS_LOG
        eval echo mbs.rom${i}.data.path=$"rom_data_path_"$i >> $MBS_LOG
    done
    echo "end of get data" >> $MBS_LOG

    #----------------------------
    # set system
    #----------------------------
    #check data valid
    eval rom_data_part=$"rom_data_part_"$rom_id
    if [ -z "$rom_data_part" ]; then
        echo rom${rom_id} data is invalid >> $MBS_LOG
        #rom_id=0

        mbs_func_err_reboot "rom${rom_id} data is invalid"
    fi
    func_get_mbs_system_setting $rom_id

    #for Debug
    echo rom_sys_part=$rom_sys_part >> $MBS_LOG
    echo rom_sys_img=$rom_sys_img >> $MBS_LOG
    echo rom_sys_path=$rom_sys_path >> $MBS_LOG
}

#------------------------------------------------------
#check rom vendor
#    no args
#------------------------------------------------------
func_vender_init()
{
    mnt_base=/mbs/mnt/rom${rom_id}
    mnt_dir=$mnt_base/sys_dev
    mnt_data=$mnt_base/data_dev
    mnt_system=/mbs/mnt/system

    eval export boot_rom_data_path=$"rom_data_path_"${rom_id}
    eval rom_data_part=$"rom_data_part_"${rom_id}

    mount -t ext4 $rom_sys_part $mnt_system || mbs_func_err_reboot "$rom_sys_part is invalid part"
    mount -t ext4 $rom_data_part $mnt_data || mbs_func_err_reboot "$rom_data_part is invalid part"
    #temporary 
    #make "data" dir is need to mount data patation.
    #echo mnt_data=$mnt_data >> $MBS_LOG
    #echo boot_rom_data_path=$boot_rom_data_path >> $MBS_LOG
    mkdir -p $boot_rom_data_path
    chmod 771 $boot_rom_data_path
    chown system.system $boot_rom_data_path

    if [ ! -f $mnt_system/build.prop ]; then
        mbs_func_err_reboot "rom${rom_id} ROM is not installed " "no init"
    fi

    rom_vender=`mbs_func_detect_rom_vendor $mnt_system`
    sh /mbs/setup_rom.sh $rom_vender $mnt_system $boot_rom_data_path
    echo rom_vender=$rom_vender >> $MBS_LOG

    # Set TweakGS2 properties
    sh /mbs/setup_tgs2.sh $boot_rom_data_path

    umount $mnt_system
    umount $mnt_data
}

#------------------------------------------------------
# put current boot rom id
#    $1:rom_id
#------------------------------------------------------
func_put_rom_id()
{
    mkdir /mbs/stat
    echo $rom_id > /mbs/stat/bootrom
}




#==============================================================================
# main process
#==============================================================================
echo $MBS_BLKDEV_DATA
mount -t ext4 $MBS_BLKDEV_DATA /xdata

func_log_init
func_mbs_init "$LOOP_CNT"
func_get_mbs_info

func_put_rom_id
func_vender_init

sh /mbs/setup_multi.sh $rom_id

mbs_func_make_init_rc "#"

cp /init.rc /xdata/init.rc
cp /init.smdk4210.rc /xdata/init.smdk4210.rc

echo end of init >> $MBS_LOG
umount /xdata
exit 0
##
