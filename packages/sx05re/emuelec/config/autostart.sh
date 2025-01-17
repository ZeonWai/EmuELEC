#!/bin/sh

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

# DO NOT modify this file, if you need to use autostart please use /storage/.config/custom_start.sh 

# while we do everything else check for BT gamepads
(
/storage/.config/emuelec/bin/btautopair.sh &
) &

# It seems some slow SDcards have a problem creating the symlink on time :/
CONFIG_DIR="/storage/.emulationstation"
CONFIG_DIR2="/storage/.config/emulationstation"

if [ ! -L "$CONFIG_DIR" ]; then
ln -sf $CONFIG_DIR2 $CONFIG_DIR
fi

# Check if we have unsynched update files
/usr/config/emuelec/scripts/force_update.sh

# Set video mode, this has to be done before starting ES
DEFE=$(sed -n 's|\s*<string name="EmuELEC_VIDEO_MODE" value="\(.*\)" />|\1|p' $CONFIG_DIR/es_settings.cfg)

if [ "${DEFE}" == "Custom" ]; then
	if [ -f "/storage/.config/EE_VIDEO_MODE" ]; then
		echo $(cat /storage/.config/EE_VIDEO_MODE) > /sys/class/display/mode
	elif [ -f "/flash/EE_VIDEO_MODE" ]; then
		echo $(cat /flash/EE_VIDEO_MODE) > /sys/class/display/mode
	fi 
else 
	[ ! -z "${DEFE}" ] && echo "${DEFE}" > /sys/class/display/mode
fi

# finally we correct the FB according to video mode
/emuelec/scripts/setres.sh

# Show splash creen 
/emuelec/scripts/show_splash.sh intro

# Clean cache garbage when boot up.
rm -rf /storage/.cache/cores/*

# handle SSH
DEFE=$(sed -n 's|\s*<bool name="SSH" value="\(.*\)" />|\1|p' $CONFIG_DIR/es_settings.cfg)

case "$DEFE" in
"true")
	mkdir -p /storage/.cache/services/
	touch /storage/.cache/services/sshd.conf
	systemctl start sshd
	;;
"false")
	systemctl stop sshd
	rm /storage/.cache/services/sshd.conf
	;;
esac

# What to start at boot?
DEFE=$(sed -n 's|\s*<string name="EmuELEC_BOOT" value="\(.*\)" />|\1|p' $CONFIG_DIR/es_settings.cfg)

case "$DEFE" in
"Retroarch")
	rm -rf /var/lock/start.retro
	touch /var/lock/start.retro
	systemctl start retroarch
	;;
*)
	rm /var/lock/start.games
	touch /var/lock/start.games
    systemctl start emustation
	;;
esac

source /storage/.config/custom_start.sh
