#!/bin/bash -e

star()
{
	echo -e "\e[33;1m*\e[0m \e[30;1m$1\e[0m \e[36m$2\e[0m"
}

usage()
{
	echo "usage:"
	echo "  `basename $0` <watch> 1.0-alpha|nightly|."
	echo "  `basename $0` <img_file> <boot_file>"
	echo "  `basename $0` ."
	exit 1
}

if [ $# -lt 1 ]; then
	usage
fi

if [ "$1" = "." ]; then
	WATCH=$MACHINE
else
	WATCH=$1
	TMP_IMG="$1"
	TMP_BOOT="$2"
fi
shift

if [ -z "$1" ] || [ "$1" = "." ]; then
	if [ -z "$BUILDDIR" ] || [ -z "$MACHINE" ]; then
		echo "not in the OE environment"
		return 1
	fi

	star "watch:" $WATCH
	TMP_IMG="$BUILDDIR/tmp-glibc/deploy/images/$WATCH/asteroid-image-$WATCH.ext4"
	TMP_BOOT="$BUILDDIR/tmp-glibc/deploy/images/$WATCH/zImage-dtb-$WATCH.fastboot"
elif [ -e "$TMP_IMG" ] && [ -e "$TMP_BOOT" ]; then
	true # everything is already set up
else
	star "watch:" $WATCH

	if [ "$1" = "1.0-alpha" ]; then
		URL_IMG="https://release.asteroidos.org/1.0-alpha/$WATCH/asteroid-image-$WATCH.ext2"
		URL_BOOT="https://release.asteroidos.org/1.0-alpha/$WATCH/zImage-dtb-$WATCH.fastboot"
	elif [ "$1" = "nightly" ]; then
		URL_IMG="https://release.asteroidos.org/nightlies/$WATCH/asteroid-image-$WATCH.ext4"
		URL_BOOT="https://release.asteroidos.org/nightlies/$WATCH/zImage-dtb-$WATCH.fastboot"
	else
		usage
	fi

	star "image URL:" $URL_IMG
	star "boot URL:" $URL_BOOT

	TMP_IMG=`mktemp asteroid-image.XXXXXX`
	star "downloading image..."
	curl -o $TMP_IMG $URL_IMG

	TMP_BOOT=`mktemp asteroid-boot.XXXXXX`
	star "downloading boot..."
	curl -o $TMP_BOOT $URL_BOOT
fi

star "image file:" $TMP_IMG
star "boot file:" $TMP_BOOT

if [ -z "`fastboot devices`" ]; then
	star "rebooting to fastboot..."
	adb reboot bootloader

	while [ -z "`fastboot devices`" ]; do
		star "waiting for fastboot..."
		sleep 3
	done
fi

star "flashing image..."
fastboot flash userdata $TMP_IMG

star "flashing boot..."
fastboot flash boot $TMP_BOOT

if [ -n "$URL_IMG" ] && [ -n "$URL_BOOT" ]; then
	star "cleanign up...."
	rm -f $TMP_IMG $TMP_BOOT
fi

star "rebooting...."
fastboot reboot
