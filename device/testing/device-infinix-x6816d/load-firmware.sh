#!/bin/sh

log() {
	logger -p daemon.info -t firmware "$@"
}

load_error() {
	log "Failed to load $FIRMWARE for $DEVPATH"
	echo "-1" > "/sys$DEVPATH/loading"
}

load_blockdev() {
	local blockdev length offset dd_args
	blockdev=$1
	length=$2
	offset=$3
	dd_args="status=none bs=512"

	if [ -n "$length" ]; then
		dd_args="$dd_args count=$((length / 512))"
	fi

	if [ -n "$offset" ]; then
		dd_args="$dd_args skip=$((offset / 512))"
	fi

	log "Loading firmware from $blockdev"

	if [ ! -e "$blockdev" ]; then
		load_error
	else
		echo 1 > "/sys$DEVPATH/loading"
		dd if="$blockdev" of="/sys$DEVPATH/data" $dd_args
		echo 0 > "/sys$DEVPATH/loading"

		log "Loading firmware complete"
	fi
}

load_partition() {
	local blockdev
	blockdev=/dev/disk/by-partlabel/$1
	shift
	load_blockdev $blockdev "$@"
}

load_zeros() {
	load_blockdev /dev/zero $1
}

log "Attempting to load firmware $FIRMWARE for $DEVPATH"

if [ -e "/sys$DEVPATH/loading" ]; then
	case "$FIRMWARE" in
		sprd/pm_sys.bin)
			load_partition pm_sys_a
			;;
		*)
			load_error
			;;
	esac
fi
