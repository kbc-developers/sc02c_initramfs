#!/sbin/busybox sh

# parameters
#  $1 = ROM_ID

#----------------------------
# /system
#----------------------------
mnt_base=/mbs/mnt/rom$1
mnt_dir=$mnt_base/sys_dev

n=`grep -n @ROM_SYS_PART_STA $INIT_RC_SRC | cut -d':' -f1`
head -n $n $INIT_RC_SRC > $INIT_RC_DST

echo  "  #-- /system
    mkdir /system
    chown root root /system
    chmod 0775 /system
    mount ext4 $rom_sys_part /system wait ro
 " >> $INIT_RC_DST
#------------------------------

#----------------------------
# /data
#----------------------------
n=`grep -n @ROM_SYS_PART_END $INIT_RC_SRC | cut -d':' -f1`
m=`grep -n @ROM_DATA_PART_STA $INIT_RC_SRC | cut -d':' -f1`
sed -n "$n,${m}p" $INIT_RC_SRC >> $INIT_RC_DST 

echo  "  
#------------------------------
    mkdir /xdata
    exec check_filesystem $DEV_BLOCK_DATA ext4
    mount ext4 $DEV_BLOCK_DATA /xdata nosuid nodev noatime wait crypt discard,noauto_da_alloc
    chown system system /xdata
    chmod 0775 /xdata

	mkdir /share
    chown system system /share
    chmod 0771 /share
 " >> $INIT_RC_DST

for i in $LOOP_CNT; do
	mnt_base=/mbs/mnt/rom${i}
	mnt_dir=$mnt_base/data_dev
	#echo "#-- rom$i data mount & link to /share/data$i"  >> $INIT_RC_DST 
	eval rom_data_part=$"rom_data_part_"$i
	eval ROM_DATA_PATH=$"ROM_DATA_PATH_"$i

	if [ ! -z "$rom_data_part" ]; then
#--------------------

echo " #---rom${i}.data
    mkdir $mnt_dir
    chown system system $mnt_dir
    chmod 0775 $mnt_dir
    mount ext4  $rom_data_part $mnt_dir nosuid nodev noatime wait crypt discard,noauto_da_alloc
    #link for share app
    symlink $ROM_DATA_PATH /share/data${i}
#------------------------------
 " >> $INIT_RC_DST
#--------------------
	fi
done

echo "#-- active rom data link to /data
    symlink $boot_rom_data_path /data

#-- app share data link to /share share
    symlink /xdata/share /share/share  
 " >> $INIT_RC_DST  
#--------------

n=`grep -n @ROM_DATA_PART_END $INIT_RC_SRC | cut -d':' -f1`
m=`wc -l $INIT_RC_SRC| cut -d' ' -f1`
sed -n "$n,${m}p" $INIT_RC_SRC >> $INIT_RC_DST 

#---------------------------




