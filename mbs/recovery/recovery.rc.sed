on early-init
    start ueventd

on init
    export PATH /sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
    export LD_LIBRARY_PATH /vendor/lib:/system/lib
    export ANDROID_ROOT /system
    export ANDROID_DATA /data
    export EXTERNAL_STORAGE /emmc
    export PHONE_STORAGE /sdcard

    # for clockworkmod
    symlink /misc /etc

    # override device prop
    setprop ro.product.device galaxys2
    setprop ro.build.product galaxys2
    setprop ro.product.board galaxys2

# create mountpoints
    mkdir /sdcard 0000 system system
    mkdir /emmc 0000 system system
    mkdir /system
    mkdir /data 0771 system system
    mkdir /cache 0770 system cache
    #mkdir /efs
    mkdir /tmp
    mkdir /dbdata

    mkdir /mnt 0775 root root

    #mount /tmp /tmp tmpfs   

on early-fs

    # rfs drivers
    insmod /lib/modules/rfs_glue.ko
    insmod /lib/modules/rfs_fat.ko

    # logcat driver
    insmod /lib/modules/logger.ko

    # parameter block
    mkdir /mnt/.lfs 0755 root root
    insmod /lib/modules/j4fs.ko
    mount j4fs /dev/block/mmcblk0p4 /mnt/.lfs


on fs
    mount tmpfs tmpfs /tmp mode=0755    
    @MBS_MOUNT_SYSTEM
    mount ext4 /dev/block/mmcblk0p7 /cache nosuid nodev noatime wait

    # SEC_DMCRYPT move mounting efs befor apply_disk_policy, and set group id to system
    #mkdir /efs
    #mount ext4 /dev/block/mmcblk0p1 /efs nosuid nodev noatime wait 
    #chown radio system /efs
    #chmod 0771 /efs

    # verfiy filesystem (UMS)
    exec apply_system_policy /dev/block/mmcblk0p11 vfat

on post-fs

    #temp
    chmod 750 /sbin/fat.format

    write /proc/sys/kernel/panic_on_oops 1
    write /proc/sys/kernel/hung_task_timeout_secs 0
    write /proc/cpu/alignment 4
    write /proc/sys/kernel/sched_latency_ns 10000000
    write /proc/sys/kernel/sched_wakeup_granularity_ns 2000000
    write /proc/sys/kernel/sched_compat_yield 1
    write /proc/sys/kernel/sched_child_runs_first 0

    # let recovery handle mounting /system
    # umount /system

on boot

    ifup lo
    hostname localhost
    domainname localdomain

    class_start default

service ueventd /sbin/ueventd
    critical

service console /sbin/sh
    console

service recovery /sbin/recovery

service adbd /sbin/adbd recovery

on property:persist.service.adb.enable=1
    start adbd

on property:persist.service.adb.enable=0
    start adbd
