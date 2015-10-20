#!/bin/bash

make BL33=~/work/GITS/u-boot/build-juno/u-boot.bin DEBUG=1 PLAT=juno LOG_LEVEL=50 BL30=/home/marc/work/linaro/recovery/SOFTWARE/bl30.bin all fip
