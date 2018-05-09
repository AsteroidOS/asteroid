#!/bin/bash
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

function pull_dir {
    if [ -d $1/.git/ ] ; then
        echo -e "\e[32mPulling $1\e[39m"
        [ "$1" != "." ]   && pushd $1 > /dev/null
        git pull --rebase
        [ $? -ne 0 ] && echo -e "\e[91mError pulling $1\e[39m"
        [ "$1" != "." ]   && popd > /dev/null
    fi
}

function clone_dir {
    if [ ! -d $1 ] ; then
        echo -e "\e[32mCloning branch $3 of $2 in $1\e[39m"
        git clone -b $3 $2 $1
        [ $? -ne 0 ] &&  echo -e "\e[91mError cloning $1\e[39m"
        if [ $# -eq 4 ]
        then
            pushd $1
            git checkout $4
            popd
        fi
    fi
}

# Update layers in src/
if [[ "$1" == "update" ]]; then
    pull_dir .
    for d in src/*/ ; do
        pull_dir $d
    done
    pull_dir src/oe-core/bitbake
elif [[ "$1" == "git-"* ]]; then
    base=$(dirname $0)
    gitcmd=${1:4} # drop git-
    shift
    for d in $base $base/src/* $base/src/oe-core/bitbake; do
        if [ $(git -C $d $gitcmd "$@" | wc -c) -ne 0 ]; then
            echo -e "\e[35mgit -C $d $gitcmd $@ \e[39m"
            git -C $d $gitcmd "$@"
        fi
    done
# Prepare bitbake
else
    ROOTDIR=`pwd`
    mkdir -p src build/conf

    if [ "$#" -gt 0 ]; then
        export MACHINE=${1}
    else
        export MACHINE=dory
    fi

    # Fetch all the needed layers in src/
    clone_dir src/oe-core              https://github.com/openembedded/openembedded-core.git rocko  d20917f3ce9ac45fb9562d1cabf7ddc212b1d07a
    clone_dir src/oe-core/bitbake      https://github.com/openembedded/bitbake.git           1.36   223a0f68530571d2280f526bddbc718fa803a3dc
    clone_dir src/meta-openembedded    https://github.com/openembedded/meta-openembedded.git rocko  dacfa2b1920e285531bec55cd2f08743390aaf57
    clone_dir src/meta-qt5             https://code.qt.io/yocto/meta-qt5.git                 5.10   v5.10.0
    clone_dir src/meta-smartphone      https://github.com/shr-distribution/meta-smartphone   rocko  a5aa51964420013149da13decabd195c58e7871b
    clone_dir src/meta-asteroid        https://github.com/AsteroidOS/meta-asteroid           1.0    8f30b00478f863ea9b0c6c87c5806a032322256a
    clone_dir src/meta-anthias-hybris  https://github.com/AsteroidOS/meta-anthias-hybris     1.0    7e45263168efcb1696732b70204bd4fc6113c8d6
    clone_dir src/meta-bass-hybris     https://github.com/AsteroidOS/meta-bass-hybris        1.0    86e1f91a9581f5481febc1f0cf84061c67aaaca1
    clone_dir src/meta-dory-hybris     https://github.com/AsteroidOS/meta-dory-hybris        1.0    7a3ba57d04cab676b0bb06c9c22623efe340de78
    clone_dir src/meta-lenok-hybris    https://github.com/AsteroidOS/meta-lenok-hybris       1.0    988cbab6aea936222ca2ae3d66624059d73db38d
    clone_dir src/meta-sparrow-hybris  https://github.com/AsteroidOS/meta-sparrow-hybris     1.0    55f5c9daf3e8e0797d9f49312e71e245f010fbe6
    clone_dir src/meta-sprat-hybris    https://github.com/AsteroidOS/meta-sprat-hybris       1.0    e64adbc6db63f7f1a90f0bdfaf8db123c3ac4a02
    clone_dir src/meta-swift-hybris    https://github.com/AsteroidOS/meta-swift-hybris       1.0    45a958f1b2b873e85cbf8fe227c8b720b6e90868
    clone_dir src/meta-tetra-hybris    https://github.com/AsteroidOS/meta-tetra-hybris       1.0    205046e375e877c0d24894aa21dd8173013e6ff2
    clone_dir src/meta-wren-hybris     https://github.com/AsteroidOS/meta-wren-hybris        1.0    0f315fbe749bcedf0278a9dab8d192f6b95dda70

    # Create local.conf and bblayers.conf on first run
    if [ ! -e $ROOTDIR/build/conf/local.conf ]; then
        echo -e "\e[32mWriting build/conf/local.conf\e[39m"
        cat >> $ROOTDIR/build/conf/local.conf << EOF
DISTRO = "asteroid"
PACKAGE_CLASSES = "package_ipk"

CONF_VERSION = "1"
BB_DISKMON_DIRS = "\\
    STOPTASKS,\${TMPDIR},1G,100K \\
    STOPTASKS,\${DL_DIR},1G,100K \\
    STOPTASKS,\${SSTATE_DIR},1G,100K \\
    ABORT,\${TMPDIR},100M,1K \\
    ABORT,\${DL_DIR},100M,1K \\
    ABORT,\${SSTATE_DIR},100M,1K" 
PATCHRESOLVE = "noop"
USER_CLASSES = "buildstats image-mklibs image-prelink"
EXTRA_IMAGE_FEATURES = "debug-tweaks"

QT_GIT_PROTOCOL = "https"
EOF
    fi

    if [ ! -e $ROOTDIR/build/conf/bblayers.conf ]; then
        echo -e "\e[32mWriting build/conf/bblayers.conf\e[39m"
        cat > $ROOTDIR/build/conf/bblayers.conf << EOF
LCONF_VERSION = "7"

BBPATH = "\${TOPDIR}"
BBFILES = ""

BBLAYERS = " \\
  $ROOTDIR/src/meta-qt5 \\
  $ROOTDIR/src/oe-core/meta \\
  $ROOTDIR/src/meta-asteroid \\
  $ROOTDIR/src/meta-openembedded/meta-oe \\
  $ROOTDIR/src/meta-openembedded/meta-multimedia \\
  $ROOTDIR/src/meta-openembedded/meta-gnome \\
  $ROOTDIR/src/meta-openembedded/meta-networking \\
  $ROOTDIR/src/meta-smartphone/meta-android \\
  $ROOTDIR/src/meta-openembedded/meta-python \\
  $ROOTDIR/src/meta-openembedded/meta-filesystems \\
  $ROOTDIR/src/meta-anthias-hybris \\
  $ROOTDIR/src/meta-sparrow-hybris \\
  $ROOTDIR/src/meta-sprat-hybris \\
  $ROOTDIR/src/meta-tetra-hybris \\
  $ROOTDIR/src/meta-bass-hybris \\
  $ROOTDIR/src/meta-dory-hybris \\
  $ROOTDIR/src/meta-lenok-hybris \\
  $ROOTDIR/src/meta-swift-hybris \\
  $ROOTDIR/src/meta-wren-hybris \\
  "
EOF
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
fi
