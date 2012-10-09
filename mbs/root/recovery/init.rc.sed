on early-init
    start ueventd

on init
    export PATH /sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
    export ANDROID_ROOT /system
    export ANDROID_DATA /data
    export EXTERNAL_STORAGE /sdcard

    symlink /misc /etc

    mkdir /sdcard
    mkdir /emmc
    mkdir /usbdisk
    mkdir /system
    mkdir /data
    mkdir /cache
    mkdir /preload
    mount /tmp /tmp tmpfs

    # override device prop
    setprop ro.product.device galaxys2
    setprop ro.build.product galaxys2
    setprop ro.product.board galaxys2

    # Touchkey led timeout 3000 msec
    write /sys/devices/virtual/misc/notification/led_timeout 3000

on fs
    mount tmpfs tmpfs /tmp mode=0755    
    @MBS_MOUNT_SYSTEM
    mount ext4 /dev/block/mmcblk0p7 /cache nosuid nodev noatime wait

    # verfiy filesystem (UMS)
    exec apply_system_policy /dev/block/mmcblk0p11 vfat

on boot
# Touchkey led timeout 3000 msec
    write /sys/devices/virtual/misc/notification/led_timeout 3000

# Permissions for mDNIe
    chown system media_rw /sys/class/mdnie/mdnie/mode
    chown system media_rw /sys/class/mdnie/mdnie/outdoor
    chown system media_rw /sys/class/mdnie/mdnie/scenario
    write /sys/class/mdnie/mdnie/scenario 4

    ifup lo
    hostname localhost
    domainname localdomain

    class_start default

service ueventd /sbin/ueventd
    critical

service console /sbin/sh
    class core
    console
    disabled
    group log
    
on property:ro.debuggable=1
    start console

service recovery /sbin/recovery

service adbd /sbin/adbd recovery
    disabled

# Always start adbd on userdebug and eng builds
on property:ro.debuggable=1
    write /sys/class/android_usb/android0/enable 0
    write /sys/class/android_usb/android0/idVendor 04e8
    write /sys/class/android_usb/android0/idProduct 685e
    write /sys/class/android_usb/android0/functions mass_storage,adb
    write /sys/class/android_usb/android0/enable 1
    write /sys/class/android_usb/android0/iManufacturer $ro.product.manufacturer
    write /sys/class/android_usb/android0/iProduct $ro.product.model
    write /sys/class/android_usb/android0/iSerial $ro.serialno
    start adbd

# Restart adbd so it can run as root
on property:service.adb.root=1
    write /sys/class/android_usb/android0/enable 0
    restart adbd
    write /sys/class/android_usb/android0/enable 1
