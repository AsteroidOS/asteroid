#!/bin/sh
# Copyright (C) 2015 Florent Revest <revestflo@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

ROOTDIR=`pwd`

# Fetch sources
mkdir -p sources build/conf
if [ ! -d sources/poky ] ; then
    git clone -b dizzy http://git.yoctoproject.org/git/poky sources/poky
fi
if [ ! -d sources/meta-openembedded ] ; then
    git clone -b dizzy https://github.com/openembedded/meta-openembedded.git sources/meta-openembedded
fi
if [ ! -d sources/meta-qt5 ] ; then
    git clone -b dizzy https://github.com/meta-qt5/meta-qt5.git sources/meta-qt5
fi
if [ ! -d sources/meta-asteroid ] ; then
    git clone https://github.com/FlorentRevest/meta-boot2efl sources/meta-asteroid
fi
if [ ! -d sources/meta-radxa-hybris ] ; then
    git clone https://github.com/FlorentRevest/meta-radxa-hybris sources/meta-radxa-hybris
fi

# Create local.conf and bblayers.conf
if [ ! -e $ROOTDIR/build/conf/local.conf ]; then
    cat >> $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "radxa-hybris"
DISTRO ?= "asteroid"
PACKAGE_CLASSES ?= "package_ipk"

CONF_VERSION = "1"
BB_DISKMON_DIRS = "\\
    STOPTASKS,\${TMPDIR},1G,100K \\
    STOPTASKS,\${DL_DIR},1G,100K \\
    STOPTASKS,\${SSTATE_DIR},1G,100K \\
    ABORT,\${TMPDIR},100M,1K \\
    ABORT,\${DL_DIR},100M,1K \\
    ABORT,\${SSTATE_DIR},100M,1K" 
PATCHRESOLVE = "noop"
USER_CLASSES ?= "buildstats image-mklibs image-prelink"
EXTRA_IMAGE_FEATURES = "debug-tweaks"
EOF
fi

if [ ! -e $ROOTDIR/build/conf/bblayers.conf ]; then
    cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
LCONF_VERSION = "5"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \\
  $ROOTDIR/sources/poky/meta \\
  $ROOTDIR/sources/meta-asteroid \\
  $ROOTDIR/sources/meta-radxa-hybris \\
  $ROOTDIR/sources/meta-openembedded/meta-oe \\
  $ROOTDIR/sources/meta-openembedded/meta-ruby \\
  $ROOTDIR/sources/meta-qt5 \\
  "
BBLAYERS_NON_REMOVABLE ?= " \\
  $ROOTDIR/sources/poky/meta \\
  $ROOTDIR/sources/meta-asteroid \\
  $ROOTDIR/sources/meta-radxa-hybris \\
  $ROOTDIR/sources/meta-openembedded/meta-oe \\
  $ROOTDIR/sources/meta-openembedded/meta-ruby \\
  $ROOTDIR/sources/meta-qt5/ \\
  "
EOF
fi

# Init build env
cd sources/poky
. ./oe-init-build-env $ROOTDIR/build > /dev/null

cat << EOF
Welcome to the Asteroid compilation script.

If you meet any issue you can report it to the project's github page:
    https://github.com/Asteroid-Project

You can now run the following command to get started with the compilation:
    bitbake asteroid-image

Have fun!
EOF
