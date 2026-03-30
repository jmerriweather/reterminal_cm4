#############################################################
#
# rethings
#
#############################################################

# Remember to bump the version when anything changes in this
# directory.
RETHINGS_SOURCE =
RETHINGS_VERSION = 0.0.1
RETHINGS_DEPENDENCIES += host-dtc

define RETHINGS_BUILD_CMDS
	cp $(NERVES_DEFCONFIG_DIR)/package/rethings/*.dts* $(@D)
	for filename in $(@D)/*.dts; do \
		$(CPP) -I$(@D) -I $(LINUX_SRCDIR)include -I $(LINUX_SRCDIR)arch -nostdinc -undef -D__DTS__ -x assembler-with-cpp $$filename | \
		$(HOST_DIR)/usr/bin/dtc -Wno-unit_address_vs_reg -@ -I dts -O dtb -b 0 \
		-o $${filename%-overlay.dts}.dtbo || exit 1; \
	done
endef

define RETHINGS_INSTALL_TARGET_CMDS
	echo "$(@D)/*.dtbo -> $(BINARIES_DIR)/rpi-firmware/overlays/"
	$(INSTALL) -D -m 0644 $(@D)/*.dtbo $(BINARIES_DIR)/rpi-firmware/overlays/
endef

$(eval $(generic-package))
