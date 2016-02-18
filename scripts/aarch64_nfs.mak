
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

make_options := -j$(makethreads) -l$(makejobs) \
		ARCH=arm64 \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		KBUILD_OUTPUT=$(build_dir)

$(config_file): FORCE
	@mkdir -p $(build_dir)
	$(MAKE) $(make_options) defconfig
	$(CURDIR)/scripts/config --file $(config_file) \
	--enable MTD \
	--enable MTD_CFI \
	--enable MTD_AFS_PARTS \
	--enable DEBUG_FS \
	--enable HIBERNATION \
	--enable ROOT_NFS \
	--disable BLK_DEV_INITRD

config: $(config_file) FORCE
	yes "" | make $(make_options) oldconfig

menuconfig: FORCE
	$(MAKE) -C $(build_dir) $(make_options) menuconfig

dtbs: FORCE
	$(MAKE) $(make_options) dtbs CONFIG_DEBUG_SECTION_MISMATCH=y
	@echo "Copy Juno DTB to $(output_dir)/juno.dtb"
	@cp -f $(build_dir)/arch/arm64/boot/dts/arm/juno.dtb $(output_dir)/juno.dtb
	@cp -f $(build_dir)/arch/arm64/boot/dts/arm/foundation-v8.dtb $(output_dir)/foundation-v8.dtb
	# If we have a TFTP boot directory
	if [ -w $(tftproot) ] ; then \
	   cp -f $(build_dir)/arch/arm64/boot/dts/arm/juno.dtb $(tftproot) ; \
	fi

zimage:  FORCE
	$(MAKE) $(make_options) Image CONFIG_DEBUG_SECTION_MISMATCH=y
	$(MAKE) $(make_options) modules
	fakeroot $(MAKE) $(make_options) modules_install
	-rm -rf /tmp/my-modules
	mkdir -p /tmp/my-modules
	fakeroot $(MAKE) INSTALL_MOD_PATH=/tmp/my-modules $(make_options) modules_install
	tar -C /tmp/my-modules  -cJvf $(JUNO_HOME)/build/modules.tar.xz lib

build:  dtbs zimage FORCE
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
	$(MAKE) clean
	rm -rf $(build_dir)

FORCE:
