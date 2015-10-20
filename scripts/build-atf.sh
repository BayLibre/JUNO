#!/bin/bash

make BL33=$JUNO_HOME/u-boot/build-juno/u-boot.bin DEBUG=1 PLAT=juno LOG_LEVEL=50 BL30=$JUNO_BINS/atf/bl30.bin all fip
