#!/sbin/busybox sh

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
#foce ROM0 boot setting
#	$1: error msg
#------------------------------------------------------
func_error()
{
	sh /mbs/err_reboot.sh $1
}

#------------------------------------------------------
#init mbs dev mnt point
#	$1: loop cnt
#------------------------------------------------------
func_mbs_init()
{
	#err staus clear (no check exist)
	rm $ERR_MSG
	
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


	if [ "$arg_img_part" = "$DEV_BLOCK_SDCARD" ] || [ "$arg_img_part" = "$DEV_BLOCK_EMMC1" ]; then
			fotmat=vfat
	fi
#format auto detect... dose not works..
#	echo dev=$dev >> $MBS_LOG
#	if [ "$dev" = "/dev/block/mmcblk0" ]; then
#		
#		if [ "$arg_img_part" = "$DEV_BLOCK_DATA" ]; then
#			fotmat="vfat"
#		fi
#	else
#		fdisk -l $dev >> $MBS_LOG
#		res=`fdisk -l $dev | grep $arg_img_part | grep -o "Win95 FAT32"`
#		echo res=$res >> $MBS_LOG
#		if [ ! -z $res ]; then
#			fotmat="vfat"
#		fi
#	fi
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
		export RET=""	4
		echo "warning)$img_path is not exist" >> $MBS_LOG
	fi
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

	# check kernel
#	KERNEL_PART=`grep mbs\.rom$rom_id\.kernel\.part $MBS_CONF | cut -d'=' -f2`
#	KERNEL_IMG=`grep mbs\.rom$rom_id\.kernel\.img $MBS_CONF | cut -d'=' -f2`
#	if [ ! -z $KERNEL_PART ];then
#		#kernel swich does not support for boot speed
#		func_check_part $KERNEL_PART $KERNEL_IMG
#		sh /mbs/init.kernel.sh $KERNEL_PART $KERNEL_IMG
#	fi

	echo "start of for" >> $MBS_LOG
	for i in $LOOP_CNT; do
		echo "for:$i" >> $MBS_LOG
		# romX setting
		rom_data_part=`grep mbs\.rom$i\.data\.part $MBS_CONF | cut -d'=' -f2`
		rom_data_img=`grep mbs\.rom$i\.data\.img $MBS_CONF | cut -d'=' -f2`
		rom_data_path=`grep mbs\.rom$i\.data\.path $MBS_CONF | cut -d'=' -f2`

		if [ ! -z "$rom_data_part" ]; then
			func_check_part $rom_data_part $rom_data_img

			mnt_base=/mbs/mnt/rom${i}
			mnt_dir=$mnt_base/data_dev

			if [ ! -z "$rom_data_img" ]; then
				func_mbs_create_loop_dev $mnt_base $rom_data_part $rom_data_img data_img data_loop 20${i}
				rom_data_part=$RET
				if [ -z "$rom_data_part" ]; then
					echo rom${i} image is not exist >> $MBS_LOG
				fi
			fi
			rom_data_path=$mnt_dir$rom_data_path
			rom_data_path=`echo $rom_data_path | sed -e "s/\/$//g"`

			eval export rom_data_part_$i=$rom_data_part
			eval export rom_data_img_$i=$rom_data_img
			eval export rom_data_path_$i=$rom_data_path

			#for Debug
			eval echo mbs.rom${i}.data.part=$"rom_data_part_"$i >> $MBS_LOG
			eval echo mbs.rom${i}.data.img=$"rom_data_img_"$i >> $MBS_LOG
			eval echo mbs.rom${i}.data.path=$"rom_data_path_"$i >> $MBS_LOG
		fi
	done

	echo "end of for" >> $MBS_LOG

	#----------------------------
	# set system
	#----------------------------
	#check data valid
	eval rom_data_part=$"rom_data_part_"$rom_id
	if [ -z "$rom_data_part" ]; then
		echo rom${rom_id} data is invalid >> $MBS_LOG
		#rom_id=0

		func_error "rom${rom_id} data is invalid"
	fi
	export rom_sys_part=`grep mbs\.rom$rom_id\.system\.part $MBS_CONF | cut -d'=' -f2`
	export rom_sys_img=`grep mbs\.rom$rom_id\.system\.img $MBS_CONF | cut -d'=' -f2`
	#export rom_sys_path=`grep mbs\.rom$rom_id\.system\.path $MBS_CONF | cut -d'=' -f2`
	export rom_sys_path="/system"

	func_check_part $rom_sys_part $rom_sys_img
	
	mnt_base=/mbs/mnt/rom${rom_id}
	mnt_dir=$mnt_base/sys_dev
	if [ ! -z "$rom_sys_img" ]; then
		echo rom_sys_img :$rom_sys_img >> $MBS_LOG	

		func_mbs_create_loop_dev $mnt_base $rom_sys_part $rom_sys_img sys_img sys_loop 10${rom_id}
		rom_sys_part=$RET
	fi

	if [ -z "$rom_sys_part" ]; then
		echo rom${rom_id} sys is invalid >> $MBS_LOG
		func_error "rom${rom_id} sys is invalid"
	fi		
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

	mount -t ext4 $rom_sys_part $mnt_system || func_error "$rom_sys_part is invalid part"
	mount -t ext4 $rom_data_part $mnt_data || func_error "$rom_data_part is invalid part"
	#temporary 
	#make "data" dir is need to mount data patation.
	#echo mnt_data=$mnt_data >> $MBS_LOG
	#echo boot_rom_data_path=$boot_rom_data_path >> $MBS_LOG
	mkdir -p $boot_rom_data_path
	chmod 771 $boot_rom_data_path
	chown system.system $boot_rom_data_path

	if [ ! -f $mnt_system/build.prop ]; then
		func_error "rom${rom_id} ROM is not installed "
	fi

	# android version code 9 or 10 is gingerbread, 14 or 15 is icecreamsandwitch
	# or 16 is jeally beans
	if [ -f $mnt_system/framework/twframework.jar ]; then
		if [ -f $mnt_system/framework/framework-miui.jar ]; then
			rom_vender=miui
		else
			rom_vender=samsung
		fi
	else
		SDK_VER=`grep ro\.build\.version\.sdk $mnt_system/build.prop | cut -d'=' -f2`
		if [ "$SDK_VER" = '16' ]; then
			rom_vender=aosp-jb
		else
			rom_vender=aosp-ics
		fi
	fi


	sh /mbs/init.$rom_vender.sh $mnt_system $boot_rom_data_path
	echo rom_vender=$rom_vender >> $MBS_LOG

	# Set TweakGS2 properties
	sh /mbs/init.tgs2.sh $boot_rom_data_path

	umount $mnt_system
	umount $mnt_data
}

#------------------------------------------------------
#make init.rc 
#    $1:rom_id
#------------------------------------------------------
func_make_init_rc()
{
	sh /mbs/init.multi.sh $1
	#sh /mbs/init.share.sh

	
	echo end of init >> $MBS_LOG

	# create init.smdk4210.rc
	#escape 
	sys_part_sed=`echo $rom_sys_part | sed -e 's/\//\\\\\\//g'`
	data_part_sed=`echo $rom_data_part | sed -e 's/\//\\\\\\//g'`

#

	sed -e "s/@SYSTEM_DEV/$sys_part_sed/g" /init.smdk4210.rc.sed | sed -e "s/@DATA_DEV/$data_part_sed/g" | sed -e "s/@MBS_COMMENT/#/g" > /init.smdk4210.rc
	#mv /init.smdk4210.rc  $rom_data_path/init.smdk4210.rc
	rm /init.smdk4210.rc.sed

	cp /init.rc /xdata/init.rc
	cp /init.smdk4210.rc /xdata/init.smdk4210.rc
}
#==============================================================================
# main process
#==============================================================================
echo $DEV_BLOCK_DATA
mount -t ext4 $DEV_BLOCK_DATA /xdata
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

#patation,path infomation init
if [ ! -f $MBS_CONF ]; then
	echo "$MBS_CONF is not exist" >> $MBS_LOG
	func_error "$MBS_CONF is not exist"
else
	func_mbs_init "$LOOP_CNT"
	func_get_mbs_info
fi
#put current boot rom nuber info
mkdir /mbs/stat
echo $rom_id > /mbs/stat/bootrom

func_vender_init
func_make_init_rc $rom_id "$LOOP_CNT"

umount /xdata
exit 0
##
