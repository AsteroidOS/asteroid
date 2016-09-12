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
    git clone -b krogoth git://git.openembedded.org/openembedded-core src/oe-core
fi
if [ ! -d src/oe-core/bitbake ] ; then
    git clone -b 1.30 git://git.openembedded.org/bitbake src/oe-core/bitbake
fi
if [ ! -d src/meta-openembedded ] ; then
    git clone -b krogoth https://github.com/openembedded/meta-openembedded.git src/meta-openembedded
fi
if [ ! -d src/meta-asteroid ] ; then
    git clone https://github.com/AsteroidOS/meta-asteroid src/meta-asteroid
fi
if [ ! -d src/meta-smartphone ] ; then
    git clone -b krogoth https://github.com/shr-distribution/meta-smartphone src/meta-smartphone
fi
if [ ! -d src/meta-qt5 ] ; then
    git clone -b krogoth https://github.com/meta-qt5/meta-qt5.git src/meta-qt5
fi

case ${1} in
    sparrow)
        if [ ! -d src/meta-tetra-hybris ] ; then
            git clone https://github.com/AsteroidOS/meta-sparrow-hybris src/meta-sparrow-hybris
        fi
        ;;
    tetra)
        if [ ! -d src/meta-tetra-hybris ] ; then
            git clone https://github.com/AsteroidOS/meta-tetra-hybris src/meta-tetra-hybris
        fi
        ;;
    bass)
        if [ ! -d src/meta-bass-hybris ] ; then
            git clone https://github.com/AsteroidOS/meta-bass-hybris src/meta-bass-hybris
        fi
        ;;
    *)
        if [ ! -d src/meta-dory-hybris ] ; then
            git clone https://github.com/AsteroidOS/meta-dory-hybris src/meta-dory-hybris
        fi
        ;;
#    newWatch)
#        if [ ! -d src/meta-newWatch-hybris ] ; then
#            git clone https://github.com/AsteroidOS/meta-newWatch-hybris src/meta-newWatch-hybris
#        fi
#        ;;
esac

# Create local.conf and bblayers.conf
if [ ! -e $ROOTDIR/build/conf/local.conf ]; then
    case ${1} in
        sparrow)
            cat > $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "sparrow"
EOF
            ;;
        tetra)
            cat > $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "tetra"
EOF
            ;;
        bass)
            cat > $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "bass"
EOF
            ;;
        *)
            cat > $ROOTDIR/build/conf/local.conf << EOF
MACHINE ??= "dory"
EOF
            ;;
#        newWatch)
#            cat > $ROOTDIR/build/conf/local.conf << EOF
#MACHINE ??= "newWatch"
#EOF
#            ;;
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
  $ROOTDIR/src/meta-openembedded/meta-oe \\
  $ROOTDIR/src/meta-openembedded/meta-ruby \\
  $ROOTDIR/src/meta-openembedded/meta-xfce \\
  $ROOTDIR/src/meta-openembedded/meta-gnome \\
  $ROOTDIR/src/meta-smartphone/meta-android \\
  $ROOTDIR/src/meta-openembedded/meta-python \\
  $ROOTDIR/src/meta-openembedded/meta-filesystems \\
EOF
    case ${1} in
        sparrow)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-sparrow-hybris \\
  "
EOF
            ;;
        tetra)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-tetra-hybris \\
  "
EOF
            ;;
        bass)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-bass-hybris \\
  "
EOF
            ;;
        *)
            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
  $ROOTDIR/src/meta-dory-hybris \\
  "
EOF
            ;;
#        newWatch)
#            cat >> $ROOTDIR/build/conf/bblayers.conf << EOF
#  $ROOTDIR/src/meta-newWatch-hybris \\
#  "
#EOF
#            ;;
    esac
fi

# Init build env
cd src/oe-core
. ./oe-init-build-env $ROOTDIR/build > /dev/null

cat << EOF
Welcome to the Asteroid compilation script.

If you meet any issue you can report it to the project's github page:
    https://github.com/AsteroidOS

You can now run the following command to get started with the compilation:
    bitbake asteroid-image

Have fun!
EOF
