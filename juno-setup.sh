#!/bin/bash


#export PATH=$PATH:/home/marc/work/GITS/buildroot/output/host/opt/ext-toolchain/bin
export JUNO_HOME=$HOME/JUNO
export JUNO_SCRIPTS=$JUNO_HOME/scripts
export JUNO_BINS=$JUNO_HOME/bins
export UBOOT_BUILD=$JUNO_HOME/build/u-boot

#aarch64 uboot tools
export PATH=$UBOOT_BUILD/tools/:$PATH

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

export BL33=$UBOOT_BUILD/u-boot.bin
export BL30=$JUNO_BINS/atf/bl30.bin DEBUG=1
export PLAT=juno
export DEBUG=1
export LOG_LEVEL=50
export INSTALL_MOD_PATH=$JUNO_HOME/buildroot/output/images

if [  -f ~/.gitconfig_BAYLIBRE  ]
then
	echo "setting RENESAS git ID"
	cp ~/.gitconfig_RENESAS ~/.gitconfig
	cp ~/.vimrc_JUNO ~/.vimrc
else
	echo "baylibre gitconfig missing?"
fi
