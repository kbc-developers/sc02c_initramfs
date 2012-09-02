
func_err_reboot()
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

func_set_feature_aosp()
{
    ROM_TYPE=$1

    mount -t proc proc /proc
    echo $ROM_TYPE > /proc/sys/kernel/feature_aosp
    umount /proc
}

func_extract_files()
{
    SRC_DIR=$1
    LIST_FILE=$2

    for FILE in `egrep -v '(^#|^$)' $LIST_FILE`; do
        cp $SRC_DIR$FILE $FILE
        echo "cp $SRC_DIR$FILE $FILE" >> $MBS_LOG
    done
}


