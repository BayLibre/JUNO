#!/bin/bash


#export PATH=$PATH:/home/marc/work/GITS/buildroot/output/host/opt/ext-toolchain/bin
export JUNO_HOME=/home/marc/work/JUNO
export JUNO_SCRIPTS=$JUNO_HOME/scripts
export JUNO_BINS=$JUNO_HOME/bins
export JUNO_KBUILD=$JUNO_HOME/kbuild

export PATH=$PATH:/home/marc/work/opt/gcc-linaro-4.9-2014.11-x86_64_aarch64-linux-gnu/bin
export PATH=$PATH:/home/marc/work/opt

#aarch64 uboot tools
export PATH=$JUNO_HOME/u-boot/build-juno/tools/:$PATH

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

export BL33=$JUNO_HOME/u-boot/u-boot.bin
export BL30=$JUNO_BINS/atf/bl30.bin DEBUG=1
export PLAT=juno
export DEBUG=1
export LOG_LEVEL=50
export INSTALL_MOD_PATH=$JUNO_HOME/buildroot/output/images

alias bd="make -C $JUNO_HOME/kbuild/ -f $JUNO_SCRIPTS/aarch64_nfs.mak build"
alias kprep="mkdir -p $JUNO_KBUILD && make -C $JUNO_HOME/linux -f $JUNO_SCRIPTS/aarch64_nfs.mak config"

