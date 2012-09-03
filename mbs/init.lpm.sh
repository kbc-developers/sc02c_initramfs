#!/sbin/busybox sh

. /mbs/mbs_funcs.sh

func_set_feature_aosp $MBS_ROM_TYPE_AOSP
sh /mbs/setup_rom.sh lpm

