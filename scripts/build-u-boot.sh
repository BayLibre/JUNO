#!/bin/bash

make CROSS_COMPILE=arm-linux-gnueabi- omap4_panda_defconfig O=pandaboard
make -C pandaboard CROSS_COMPILE=arm-linux-gnueabi-
