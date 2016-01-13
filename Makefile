#
# Copyright (c) 2015 BayLibre SAS
#
# Top level Makefile for the JUNO
#
ifndef JUNO_HOME
 $(error you need to source juno-setup, or define the matching variables)
endif

all: kernel u-boot rootfs BL33
	-@cat .log

##
# Kernel stuff
##

$(KERNEL_BUILD)/arch/arm/boot/zImage: kernel

kernel: $(KERNEL_BUILD)/.config rootfs
	make -C $(KERNEL_BUILD) -f $(JUNO_SCRIPTS)/aarch64_nfs.mak build

menuconfig: $(KERNEL_BUILD)/.config
	ARCH=arm64 make -C $(KERNEL_BUILD) menuconfig

config: $(KERNEL_BUILD)/.config

$(KERNEL_BUILD)/.config: rootfs
	@mkdir -p $(KERNEL_BUILD)
	make -C $(KERNEL_SRC) -f  $(JUNO_SCRIPTS)/aarch64_nfs.mak config


##
# BUILDROOT and ROOTFS
##
$(JUNO_HOME)/buildroot/.config:
	@echo "preparing buildroot"
	make -C $(JUNO_HOME)/buildroot arm_foundationv8_defconfig
	cd $(JUNO_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable TARGET_ROOTFS_TAR
	cd $(JUNO_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_TRACE_CMD
	cd $(JUNO_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_AVAHI
	cd $(JUNO_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_AVAHI_DAEMON
	cd $(JUNO_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LIBDAEMON
	cd $(JUNO_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_EXPAT


# create rootfs.tar.xz
#

rootfs: rootfs.tar.xz

rootfs.tar.xz: $(INSTALL_MOD_PATH)/.rootfs
	xz -kc $(JUNO_HOME)/buildroot/output/images/rootfs.tar > rootfs.tar.xz

$(INSTALL_MOD_PATH)/.rootfs: $(JUNO_HOME)/buildroot/output/images/rootfs.tar
	@mkdir -p $(INSTALL_MOD_PATH)
	sudo tar xv -C $(INSTALL_MOD_PATH) -f $(JUNO_HOME)/buildroot/output/images/rootfs.tar
	sudo chown ${USER}:${USER}  $(INSTALL_MOD_PATH)
	@date > $(INSTALL_MOD_PATH)/.rootfs

$(JUNO_HOME)/buildroot/output/images/rootfs.tar: $(JUNO_HOME)/buildroot/.config
	make -C $(JUNO_HOME)/buildroot -j 5

##
# ARM Trusted Firmware
##

BL33: u-boot
	make -C $(JUNO_HOME)/arm-trusted-firmware \
	BL33=$(UBOOT_BUILD)/u-boot.bin DEBUG=1 PLAT=juno LOG_LEVEL=50 \
	BL30=$(JUNO_BINS)/atf/bl30.bin all fip
	$(JUNO_SCRIPTS)/deploy-atf

##
# U_BOOT
##

u-boot: $(UBOOT_BUILD)/u-boot.bin

$(UBOOT_BUILD)/u-boot.bin: $(UBOOT_BUILD)/.config
	@mkdir -p $(UBOOT_BUILD)
	make -C $(UBOOT_BUILD) ARCH=arm -j4

$(UBOOT_BUILD)/.config:
	@make -C $(UBOOT_SRC) O=$(UBOOT_BUILD) ARCH=arm64 vexpress_aemv8a_juno_defconfig
	@echo "fix u-boot config for NFS boot"
	@cd $(UBOOT_SRC) && git checkout include/configs/vexpress_aemv8a.h -f
	@cd $(UBOOT_SRC) && patch -p1 < $(JUNO_HOME)/uenv/u-boot-vexpress_aemv8a_h.patch
	@sed 's#INSTALL_MOD_PATH#'"${INSTALL_MOD_PATH}"'#' -i $(UBOOT_SRC)/include/configs/vexpress_aemv8a.h
	@sed 's#SERVERIP#'"${SERVERIP}"'#' -i  $(UBOOT_SRC)/include/configs/vexpress_aemv8a.h
	@sed 's#BOARDIP#'"${BOARDIP}"'#' -i  $(UBOOT_SRC)/include/configs/vexpress_aemv8a.h

##
# cleanup
##

distclean: clean
	-@rm -f patches/.applied
	-@rm -rf $(KERNEL_BUILD)
	make -C $(KERNEL_SRC) mrproper
	make -C arm-trusted-firmware realclean
	make -C buildroot clean
	make -C u-boot mrproper
	sudo rm -rf rootfs rootfs.tar.xz
	echo "" > .log

clean:
	-@rm -rf $(KERNEL_BUILD)
	-@rm -rf $(UBOOT_BUILD)
	-@sudo rm $(JUNO_HOME)/buildroot/output/images/rootfs.tar
	-@rm $(INSTALL_MOD_PATH)/.rootfs


help:
	@echo "Source acme-setup first, after revising the various variables and pathes"
	@echo "If you wish to experiment with IIO, you may export JUNO_IIO=1 so that"
	@echo "the makefile automates the right setup for buildroot and kernel"
	@echo
	@echo " == Make Targets == "
	@echo
	@echo "all			build everything, except the sdcard contents"
	@echo
	@echo "kernel, menuconfig	configure and build the kernel, or menuconfig"
	@echo "u-boot			build u-boot"
	@echo "rootfs			create a bootable rootfs"
	@echo
	@echo "clean			clean the kernel and uboot"
	@echo "distclean		flush all the build, including buildroot"
	@echo
	@echo " == Building the SDCard == "
	@echo
	@echo "sdcard			create the sdcard contents, please use with care."
	@echo
	make -C sdcard help
