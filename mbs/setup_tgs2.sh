#!/sbin/busybox sh

PROP_PATH=$1/tweakgs2.prop

LOGGER=`grep ro\.tgs2\.logger $PROP_PATH | cut -d'=' -f2`
if [ "$LOGGER" = '1' ] || [ -z "$LOGGER" ] ; then
    insmod /lib/modules/logger.ko
fi

CIFS=`grep ro\.tgs2\.cifs $PROP_PATH | cut -d'=' -f2`
if [ "$CIFS" = '1' ]; then
    insmod /lib/modules/cifs.ko
fi

NTFS=`grep ro\.tgs2\.ntfs $PROP_PATH | cut -d'=' -f2`
if [ "$NTFS" = '1' ]; then
    insmod /lib/modules/ntfs.ko
fi

J4FS=`grep ro\.tgs2\.j4fs $PROP_PATH | cut -d'=' -f2`
if [ "$J4FS" = '1' ]; then
    insmod /lib/modules/j4fs.ko
fi

