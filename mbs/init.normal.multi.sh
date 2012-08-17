#!/sbin/busybox sh

#set config
BUILD_TARGET=$1

export LOOP_CNT="0 1 2 3 4 5 6 7"
export RET=""

#note)script process is "main process" is 1st

#------------------------------------------------------
#foce ROM0 boot setting
#	$1: error msg
#------------------------------------------------------
func_error()
{
	sh err_reboot.sh $1
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
#foce ROM0 boot setting
#	$1: mount data path ( single / multi switch )
#------------------------------------------------------
func_mbs_foce_pramary()
{
	export rom_id=0
	export rom_data_part_0=$DEV_BLOCK_DATA
	export rom_data_img_0=""
	#wraning last "/" is not need
	export rom_data_path_0=/mbs/mnt/rom0/data_dev$1

	export rom_sys_part=$DEV_BLOCK_FACTORYFS
	export rom_sys_img=""
	#wraning last "/" is not need
	#export rom_sys_path=/mbs/mnt/rom0/sys_dev
	export rom_sys_path="/system"
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
	KERNEL_PART=`grep mbs\.rom$rom_id\.kernel\.part $MBS_CONF | cut -d'=' -f2`
	KERNEL_IMG=`grep mbs\.rom$rom_id\.kernel\.img $MBS_CONF | cut -d'=' -f2`
	if [ ! -z $KERNEL_PART ];then
		func_check_part $KERNEL_PART $KERNEL_IMG
		sh /mbs/init.kernel.sh $KERNEL_PART $KERNEL_IMG
	fi

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
		#func_mbs_foce_pramary  "/data0"
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

	# android version code 9 or 10 is gingerbread, 14 or 15 is icecreamsandwitch
	# or 16 is jeally beans
	if [ -f $mnt_system/framework/twframework.jar ]; then
		if [ -f $mnt_system/framework/framework-miui.jar ]; then
			rom_vender=miui
		    sh /mbs/init.miui.sh $mnt_system $boot_rom_data_path
		else
			rom_vender=samsung
		    sh /mbs/init.samsung.sh $mnt_system $boot_rom_data_path
		fi
	else
		SDK_VER=`grep ro\.build\.version\.sdk $mnt_system/build.prop | cut -d'=' -f2`
		if [ "$SDK_VER" = '16' ]; then
			rom_vender=aosp-jb
		    sh /mbs/init.aosp-jb.sh $mnt_system $boot_rom_data_path
		else
			rom_vender=aosp-ics
		    sh /mbs/init.aosp-ics.sh $mnt_system $boot_rom_data_path
		fi
	fi


	sh /mbs/init.$rom_vender.sh $mnt_system $boot_rom_data_path
	echo rom_vender=$rom_vender >> $MBS_LOG
	cp /mbs/init.rc.temp /xdata/init.rc.temp

	# Set TweakGS2 properties
	sh /mbs/init.tgs2.sh $boot_rom_data_path

	umount $mnt_system
	umount $mnt_data
}

#------------------------------------------------------
#make init.rc 
#    $1:rom_id
#    $2:LOOP_CNT
#------------------------------------------------------
func_make_init_rc()
{
	if [ "$BUILD_TARGET" = '2' ]; then
		sh /mbs/init.multi.sh $1 $2
		#sh /mbs/init.share.sh
	else
		sh /mbs/init.single.sh 0
	fi

	cp /init.rc /xdata/init.rc

	echo end of init >> $MBS_LOG

	#mbs dir remove,if single boot 
	if [ "$BUILD_TARGET" != '2' ]; then
		rm -r /mbs
		rmdir /xdata
	fi
}
#==============================================================================
# main process
#==============================================================================
BOOT_DATE=`date`

#log backup----------------
if [ -f $MBS_LOG_1 ]; then
	mv $MBS_LOG_1 $MBS_LOG_2
fi
if [ -f $MBS_LOG ]; then
	mv $MBS_LOG $MBS_LOG_1
fi
#-------------------------

echo "boot start : $BOOT_DATE" > $MBS_LOG

if [ "$BUILD_TARGET" = '2' ]; then

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

else
	#/system is synbolic link when multi boot.
	func_mbs_init 
	func_mbs_foce_pramary
fi

func_vender_init
func_make_init_rc $rom_id $LOOP_CNT

exit 0
##
