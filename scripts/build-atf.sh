#!/bin/bash
make BL33=$JUNO_HOME/u-build/u-boot.bin DEBUG=1 PLAT=juno LOG_LEVEL=50 BL30=$JUNO_BINS/atf/bl30.bin all fip
if [ -f /media/marc/JUNO/SOFTWARE/fip.bin ]
then
 echo "copying to Juno SOFTWARE"
 ../scripts/deploy.sh
fi
