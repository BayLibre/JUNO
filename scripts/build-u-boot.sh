#!/bin/bash

make vexpress_aemv8a_juno_defconfig O=../u-build
make -C ../u-build -j 4
