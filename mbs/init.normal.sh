#!/sbin/busybox sh

. /mbs/mbs_const
. /mbs/mbs_funcs.sh

BOOT_MODE=$1

#note)script process is "main process" is 1st
#------------------------------------------------------
#init log
#    $1: loop cnt
#------------------------------------------------------
mbs_func_init_log()
{
    BOOT_MODE_=$1

	export MBS_LOG=$MBS_CTL_PATH/mbs.log
	export MBS_LOG_1="$MBS_CTL_PATH/mbs.old1.log"
	export MBS_LOG_2="$MBS_CTL_PATH/mbs.old2.log"
	export MBS_CONF="$MBS_CTL_PATH/mbs.conf"
	export ERR_MSG="$MBS_CTL_PATH/mbs.err"

    #log backup----------------
    if [ -f $MBS_LOG_1 ]; then
        mv $MBS_LOG_1 $MBS_LOG_2
    fi
    if [ -f $MBS_LOG ]; then
        mv $MBS_LOG $MBS_LOG_1
    fi
    #-------------------------
    boot_date=`date`
    echo "boot start $BOOT_MODE_: $boot_date" > $MBS_LOG
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
        mbs_func_err_reboot "$MBS_CONF is not exist"
    fi

    #/system is synbolic link when multi boot.
    #rmdir /system
    #system is directory mount 2012/02/05
    mkdir /system
    chmod 755 /system
    
    #make mbs dev mnt point
    chmod 755 /mbs/mnt
    for i in $LOOP_CNT; do
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

    #for debug
    mbs_func_print_log "img_part=$arg_img_part"
    mbs_func_print_log "mnt_img=$mnt_img"
    mbs_func_print_log "img_path=$img_path"
    mbs_func_print_log "dev_loop=$dev_loop"
    
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
    mbs_func_print_log "fotmat=$fotmat"
    
    if [ "$fotmat" = 'vfat' ]; then
        mount -t $fotmat $arg_img_part $mnt_img
    else
        mount -t $fotmat $arg_img_part $mnt_img
    fi
    #echo `ls -l $mnt_img` >> $MBS_LOG
    # set loopback devce
    if [ -f $img_path ]; then
        mbs_func_print_log "create loop: $dev_loop"
        mknod $dev_loop b 7 ${arg_dev_id}
        losetup $dev_loop $img_path
        echo $dev_loop
    else
        umount $mnt_img
        echo ""
        mbs_func_print_log "warning)$img_path is not exist"
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
            rom_data_part=`func_mbs_create_loop_dev $mnt_base $rom_data_part $rom_data_img data_img data_loop 20${arg_rom_id}`
            if [ -z "$rom_data_part" ]; then
                mbs_func_print_log "rom${arg_rom_id} image is not exist"
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
        mbs_func_print_log "rom_sys_img :$rom_sys_img"
        rom_sys_part=`func_mbs_create_loop_dev $mnt_base $rom_sys_part $rom_sys_img sys_img sys_loop 10${arg_rom_id}`
    fi

    if [ -z "$rom_sys_part" ]; then
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
    mbs_func_print_log "rom_id : $rom_id"
    #----------------------------
    # set kernel
    #----------------------------
    #func_get_mbs_kernel_setting

    #----------------------------
    # set data
    #----------------------------
    mbs_func_print_log "start of get data "
    for i in $LOOP_CNT; do
        mbs_func_print_log "ROM:$i"
        func_get_mbs_data_setting $i
        #for Debug
        eval mbs_func_print_log mbs.rom${i}.data.part=$"rom_data_part_"$i
        eval mbs_func_print_log mbs.rom${i}.data.img=$"rom_data_img_"$i
        eval mbs_func_print_log mbs.rom${i}.data.path=$"rom_data_path_"$i
    done
    mbs_func_print_log "end of get data"

    #----------------------------
    # set system
    #----------------------------
    #check data valid
    eval rom_data_part=$"rom_data_part_"$rom_id
    if [ -z "$rom_data_part" ]; then
        mbs_func_err_reboot "rom${rom_id} data is invalid"
    fi
    func_get_mbs_system_setting $rom_id

    mnt_base=/mbs/mnt/rom${rom_id}
    mnt_dir=$mnt_base/sys_dev
    export mnt_data=$mnt_base/data_dev
    export mnt_system=/mbs/mnt/system

    eval export boot_rom_data_path=$"rom_data_path_"${rom_id}
    eval rom_data_part=$"rom_data_part_"${rom_id}


    #for Debug
    mbs_func_print_log "rom_sys_part=$rom_sys_part"
    mbs_func_print_log "rom_sys_img=$rom_sys_img"
    mbs_func_print_log "rom_sys_path=$rom_sys_path"
}

#------------------------------------------------------
#check rom vendor
#    no args
#------------------------------------------------------
func_vender_init()
{
	rom_sys_part_=$1
	rom_sys_path_=$2
	rom_data_part_=$3
	rom_data_path_=$4

    mount -t ext4 $rom_sys_part_ $rom_sys_path_ || mbs_func_err_reboot "$rom_sys_part_ is invalid part"
    mount -t ext4 $rom_data_part_ $rom_data_path_ || mbs_func_err_reboot "$rom_data_part_ is invalid part"

    mkdir -p $rom_data_path_
    chmod 771 $rom_data_path_
    chown system.system $rom_data_path_

    if [ ! -f $rom_sys_path_/build.prop ]; then
        mbs_func_err_reboot "ROM is not installed" "no init"
    fi
	
	# check rom vendor
	rom_vendor=`mbs_func_detect_rom_vendor $rom_sys_path_`
	sh /mbs/setup_rom.sh $rom_vendor $rom_sys_path_ $rom_data_path_
    mbs_func_print_log "rom_vendor=$rom_vendor"

    # Set TweakGS2 properties
    sh /mbs/setup_tgs2.sh $rom_data_path_

	umount $rom_sys_path_
	umount $rom_data_path_
}
#------------------------------------------------------
# make init.xx.rc
#    $1:sys part
#    $2:data part
#    $3:comment or not
#------------------------------------------------------
func_make_init_rc()
{
    SYS_PART_=`echo $1 | sed -e 's/\//\\\\\\//g'`
    DATA_PART_=`echo $2 | sed -e 's/\//\\\\\\//g'`
    COMMENT_=$3

    sed -e "s/@SYSTEM_DEV/$SYS_PART_/g" /init.smdk4210.rc.sed | sed -e "s/@DATA_DEV/$DATA_PART_/g" | sed -e "s/@MBS_COMMENT/$COMMENT_/g" > /init.smdk4210.rc
    rm /init.smdk4210.rc.sed
}
#------------------------------------------------------
# put current boot rom id
#    $1:rom_id
#------------------------------------------------------
func_put_rom_id()
{
    mkdir -p $MBS_STAT_PATH
    echo $rom_id > $MBS_STAT_PATH/bootrom
}

#==============================================================================
# each mode main
#==============================================================================
func_init_multi()
{
	cp /mbs/swrom /sbin

	func_mbs_init
	func_get_mbs_info
	
	func_put_rom_id
	func_vender_init $rom_sys_part $mnt_system $rom_data_part $mnt_data 

	# create init.rc
	sh /mbs/setup_multi.sh $rom_id
	# create init.smdk4210.rc
	func_make_init_rc $rom_sys_part $rom_data_part "#"

	#for debug
	cp /init.rc $MBS_CTL_PATH/init.rc
	cp /init.smdk4210.rc $MBS_CTL_PATH/init.smdk4210.rc
}

func_init_single()
{
    mkdir /system
    mkdir /data
    chmod 0771 /data

    rom_sys_path=/mbs/mnt/system
    rom_data_path=/mbs/mnt/data
    rom_sys_part=$MBS_BLKDEV_FACTORYFS
    rom_data_part=$MBS_BLKDEV_DATA

	func_vender_init $rom_sys_part $rom_sys_path $rom_data_part $rom_data_path

	# create init.smdk4210.rc
	func_make_init_rc $rom_sys_part_ $rom_data_part_

	# create init.rc
	mv /init.rc.sed /init.rc
}
#==============================================================================
# main process
#==============================================================================
mkdir $MBS_CTL_PATH

mount -t ext4 $MBS_BLKDEV_DATA $MBS_CTL_PATH

if [ "$BOOT_MODE" = "$MBS_BOOT_MODE_MULTI" ]; then
    mbs_func_init_log "mbs mode"
    func_init_multi
else
    mbs_func_init_log "single mode"
    func_init_single
fi

mbs_func_print_log "end of init"
umount $MBS_CTL_PATH
exit 0
##
