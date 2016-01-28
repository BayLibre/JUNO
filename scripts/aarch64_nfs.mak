
## NFS VARIANT ## 

CROSS_COMPILE	:= aarch64-linux-gnu-
build_dir       := $(KERNEL_BUILD)
output_dir	:= $(JUNO_HOME)/build
rootfs		:= $(INSTALL_MOD_PATH)
config_file     := $(build_dir)/.config
makejobs	:= $(shell grep '^processor' /proc/cpuinfo | sort -u | wc -l)
makethreads	:= $(shell dc -e "$(makejobs) 1 + p")
tftproot	:= /var/lib/tftpboot

serverip := $(SERVERIP)

make_options := -f Makefile \
		-j$(makethreads) -l$(makejobs) \
		ARCH=arm64 \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		KBUILD_OUTPUT=$(build_dir)

.PHONY: help
help:
	@echo "****  Common Makefile  ****"
	@echo "make config - configure for aarch64"
	@echo "make build - build the kernel with initramfs"

.PHONY: have-crosscompiler
have-crosscompiler:
	@echo -n "Check that $(CROSS_COMPILE)gcc is available..."
	@which $(CROSS_COMPILE)gcc > /dev/null ; \
	if [ ! $$? -eq 0 ] ; then \
	   echo "ERROR: cross-compiler $(CROSS_COMPILE)gcc not in PATH=$$PATH!" ; \
	   echo "ABORTING." ; \
	   exit 1 ; \
	else \
	   echo "OK" ;\
	fi

config-base: FORCE
	@mkdir -p $(build_dir)
	$(MAKE) $(make_options) defconfig
	$(CURDIR)/scripts/config --file $(config_file) \
	--enable MTD \
	--enable MTD_CFI \
	--enable MTD_AFS_PARTS \
	--enable DEBUG_FS

config-nfs: config-base FORCE
	$(CURDIR)/scripts/config --file $(config_file) \
	--enable ROOT_NFS \
	--disable BLK_DEV_INITRD

config: config-base config-nfs FORCE
	yes "" | make $(make_options) oldconfig

menuconfig: FORCE
	if [ ! -d $(build_dir) ] ; then \
	   echo "no build dir" ; \
	   exit 1 ; \
        fi
	$(MAKE) $(make_options) menuconfig
	$(MAKE) $(make_options) savedefconfig

saveconfig: FORCE
	yes "" | make $(make_options) oldconfig
	$(MAKE) $(make_options) savedefconfig
	cp $(build_dir)/defconfig arch/arm64/configs/defconfig

build-dtbs: FORCE
	$(MAKE) $(make_options) dtbs CONFIG_DEBUG_SECTION_MISMATCH=y
	@echo "Copy Juno DTB to $(output_dir)/juno.dtb"
	@cp -f $(build_dir)/arch/arm64/boot/dts/arm/juno.dtb $(output_dir)/juno.dtb
	@cp -f $(build_dir)/arch/arm64/boot/dts/arm/foundation-v8.dtb $(output_dir)/foundation-v8.dtb
	# If we have a TFTP boot directory
	if [ -w $(tftproot) ] ; then \
	   cp -f $(build_dir)/arch/arm64/boot/dts/arm/juno.dtb $(tftproot) ; \
	fi

build-zimage: have-crosscompiler FORCE
	$(MAKE) $(make_options) Image CONFIG_DEBUG_SECTION_MISMATCH=y

build: have-crosscompiler build-dtbs build-zimage FORCE
	@echo "Copy vmlinux to $(output_dir)/vmlinux"
	@cp -f $(build_dir)/vmlinux $(output_dir)/vmlinux
	@echo "Copy Image to $(output_dir)/Image"
	@cp -f $(build_dir)/arch/arm64/boot/Image $(output_dir)/Image
	@which mkimage > /dev/null ; \
	if [ ! $$? -eq 0 ] ; then \
	   echo "mkimage not in PATH=$$PATH" ; \
	   echo "This tool creates the uImage and comes from the uboot tools" ; \
	   echo "On Ubuntu/Debian sudo apt-get install uboot-mkimage" ; \
	   echo "SKIPPING uImage GENERATION" ; \
	else \
	   mkimage \
		-A arm64 \
		-O linux \
		-T kernel \
		-C none \
		-a 0x80080000 \
		-e 0x80080000 \
		-n "AARCH64 kernel" \
		-d $(output_dir)/Image \
		$(output_dir)/uImage ; \
	fi
	# If we have a TFTP boot directory
	if [ -w $(tftproot) ] ; then \
	   cp $(output_dir)/Image $(tftproot) ; \
	   cp $(output_dir)/uImage $(tftproot) ; \
	fi
	@echo "TFTP boot:"
	@echo "set serverip $(serverip) ; set ipaddr 192.168.2.59 ; tftpboot 0x80000000 Image ; tftpboot 0x83000000 juno.dtb ; booti 0x80000000 - 0x83000000"

clean:
	$(MAKE) -f Makefile clean
	rm -rf $(build_dir)

FORCE:
