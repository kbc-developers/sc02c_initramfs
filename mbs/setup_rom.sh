#!/sbin/busybox sh

. /mbs/mbs_funcs.sh

ROM_NAME=$1
SYSTEM_DIR=$2
DATA_DIR=$3

setup_rom_aosp()
{
    NAME=$1

    func_set_feature_aosp $MBS_ROM_TYPE_AOSP
    func_extract_files /mbs/$NAME /mbs/$NAME/$NAME.list
}

setup_rom_samsung()
{
    NAME=$1

    func_set_feature_aosp $MBS_ROM_TYPE_SAMSUNG
    func_extract_files /mbs/$NAME /mbs/$NAME/$NAME.list

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

    if [ $NAME = "samsung" ]; then
        # fix LPG Camera/movie
        chmod 640 $SYSTEM_DIR/lib/hw/hwcomposer.exynos4.so
    fi
}

case "$ROM_NAME" in
  "aosp-ics" ) setup_rom_aosp aosp-ics ;;
  "aosp-jb" ) setup_rom_aosp aosp-jb ;;
  "lpm" ) setup_rom_aosp lpm ;;
  "miui" ) setup_rom_samsung miui ;;
  "samsung" ) setup_rom_samsugn samsung ;;
  * ) func_err_reboot "error: not found ROM_NAME" ;;
esac

