#!/sbin/busybox sh

. /mbs/mbs_funcs.sh

ROM_NAME=$1
SYSTEM_DIR=$2
DATA_DIR=$3

func_setup_recovery()
{
    NAME=$1

    msb_func_set_feature_aosp $MBS_ROM_TYPE_AOSP
    msb_func_extract_files /mbs/root/recovery /mbs/root/recovery/$NAME-file.list
}

func_setup_aosp()
{
    NAME=$1

    msb_func_set_feature_aosp $MBS_ROM_TYPE_AOSP
    msb_func_extract_files /mbs/root/$NAME /mbs/root/$NAME/file.list
}

func_setup_samsung()
{
    NAME=$1

    msb_func_set_feature_aosp $MBS_ROM_TYPE_SAMSUNG
    msb_func_extract_files /mbs/root/$NAME /mbs/root/$NAME/file.list

    # check bootanimation
    if [ -f $DATA_DIR/local/bootanimation.zip ] || [ -f $SYSTEM_DIR/media/bootanimation.zip ]; then
        BOOTANI_UID="root"
        # bootanimation wait one loop
        BOOTANIM_WAIT="setprop sys.bootanim_wait 1"
    else
        BOOTANI_UID="graphics"
        BOOTANIM_WAIT=""
    fi
    sed -e "s/@BOOTANI_UID/$BOOTANI_UID/g" /init.rc.sed.sed | sed -e "s/@BOOTANIM_WAIT/$BOOTANIM_WAIT/g" > /init.rc.sed
    rm /init.rc.sed.sed

    if [ $NAME = "samsung" ]; then
        # fix LPG Camera/movie
        chmod 640 $SYSTEM_DIR/lib/hw/hwcomposer.exynos4.so
    fi
}


case "$ROM_NAME" in
  "recovery-single" ) func_setup_recovery single ;;
  "recovery-multi" ) func_setup_recovery multi ;;
  "lpm" ) func_setup_aosp lpm ;;
  "aosp-ics" ) func_setup_aosp aosp-ics ;;
  "aosp-jb" ) func_setup_aosp aosp-jb ;;
  "miui" ) func_setup_samsung miui ;;
  "samsung" ) func_setup_samsung samsung ;;
  * ) mbs_func_err_reboot "error: not found ROM_NAME=$ROM_NAME" ;;
esac

