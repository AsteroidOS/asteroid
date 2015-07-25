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
mkdir -p src build/conf
if [ ! -d src/oe-core ] ; then
    git clone -b fido git://git.openembedded.org/openembedded-core src/oe-core
fi
if [ ! -d src/oe-core/bitbake ] ; then
    git clone -b 1.26 git://git.openembedded.org/bitbake src/oe-core/bitbake
fi
if [ ! -d src/meta-openembedded ] ; then
    git clone -b master https://github.com/openembedded/meta-openembedded.git src/meta-openembedded
fi
if [ ! -d src/meta-asteroid ] ; then
    git clone https://github.com/Asteroid-Project/meta-asteroid src/meta-asteroid
fi
if [ ! -d src/meta-smartphone ] ; then
    git clone -b fido https://github.com/shr-distribution/meta-smartphone src/meta-smartphone
fi
if [ ! -d src/meta-virtualization ] ; then
    git clone -b fido http://git.yoctoproject.org/git/meta-virtualization src/meta-virtualization
fi
if [ ! -d src/meta-qt5 ] ; then
    git clone -b fido https://github.com/meta-qt5/meta-qt5.git src/meta-qt5
fi

case ${1} in
    dory)
        if [ ! -d src/meta-dory-hybris ] ; then
            git clone https://github.com/Asteroid-Project/meta-dory-hybris src/meta-dory-hybris
        fi
        ;;
    cubie)
        if [ ! -d src/meta-cubie-hybris ] ; then
            git clone https://github.com/FlorentRevest/meta-cubie-hybris src/meta-cubie-hybris
        fi
        if [ ! -d src/meta-sunxi ] ; then
            git clone https://github.com/linux-sunxi/meta-sunxi src/meta-sunxi
        fi
        ;;
    odroid)
        if [ ! -d src/meta-odroid-hybris ] ; then
            git clone https://github.com/FlorentRevest/meta-odroid-hybris src/meta-odroid-hybris
        fi
        if [ ! -d src/meta-amlogic ] ; then
            git clone https://github.com/linux-meson/meta-amlogic.git src/meta-amlogic
        fi
        ;;
    *)
        if [ ! -d src/meta-radxa-hybris ] ; then
            git clone https://github.com/FlorentRevest/meta-radxa-hybris src/meta-radxa-hybris
        fi
        if [ ! -d src/meta-rockchip ] ; then
            git clone https://github.com/linux-rockchip/meta-rockchip src/meta-rockchip
        fi
        ;;
esac

# Create local.conf and bblayers.conf
if [ ! -e $ROOTDIR/build/conf/local.conf ]; then
    case ${1} in
        dory)
            cat > $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "dory"
EOF
            ;;
        cubie)
            cat > $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "cubieboard"
EOF
            ;;
        odroid)
            cat > $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "odroidc1"
EOF
            ;;
        *)
            cat > $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "rk3188-radxarock"
EOF
            ;;
    esac
    cat >> $ROOTDIR/build/conf/local.conf << EOF
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
    cat > $ROOTDIR/build/conf/bblayers.conf << EOF
LCONF_VERSION = "6"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \\
  $ROOTDIR/src/meta-qt5 \\
  $ROOTDIR/src/oe-core/meta \\
  $ROOTDIR/src/meta-asteroid \\
  $ROOTDIR/src/meta-virtualization \\
  $ROOTDIR/src/meta-openembedded/meta-oe \\
  $ROOTDIR/src/meta-openembedded/meta-ruby \\
  $ROOTDIR/src/meta-openembedded/meta-gnome \\
  $ROOTDIR/src/meta-smartphone/meta-android \\
  $ROOTDIR/src/meta-openembedded/meta-python \\
  $ROOTDIR/src/meta-openembedded/meta-networking \\
EOF
    case ${1} in
        dory)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-dory-hybris \\
EOF
            ;;
        cubie)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-sunxi \\
  $ROOTDIR/src/meta-cubie-hybris \\
EOF
            ;;
        odroid)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-amlogic \\
  $ROOTDIR/src/meta-odroid-hybris \\
EOF
            ;;
        *)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-rockchip \\
  $ROOTDIR/src/meta-radxa-hybris \\
EOF
            ;;
    esac
    cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  "
BBLAYERS_NON_REMOVABLE ?= " \\
  $ROOTDIR/src/meta-qt5 \\
  $ROOTDIR/src/oe-core/meta \\
  $ROOTDIR/src/meta-asteroid \\
  $ROOTDIR/src/meta-virtualization \\
  $ROOTDIR/src/meta-openembedded/meta-oe \\
  $ROOTDIR/src/meta-openembedded/meta-ruby \\
  $ROOTDIR/src/meta-openembedded/meta-gnome \\
  $ROOTDIR/src/meta-smartphone/meta-android \\
  $ROOTDIR/src/meta-openembedded/meta-python \\
  $ROOTDIR/src/meta-openembedded/meta-networking \\
EOF
    case ${1} in
        dory)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-dory-hybris \\
  "
EOF
            ;;
        cubie)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-sunxi \\
  $ROOTDIR/src/meta-cubie-hybris \\
  "
EOF
            ;;
        odroid)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-amlogic \\
  $ROOTDIR/src/meta-odroid-hybris \\
  "
EOF
            ;;
        *)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-rockchip \\
  $ROOTDIR/src/meta-radxa-hybris \\
  "
EOF
            ;;
    esac
fi

# Init build env
cd src/oe-core
. ./oe-init-build-env $ROOTDIR/build > /dev/null

cat << EOF
Welcome to the Asteroid compilation script.

If you meet any issue you can report it to the project's github page:
    https://github.com/Asteroid-Project

You can now run the following command to get started with the compilation:
    bitbake asteroid-image

Have fun!
EOF
