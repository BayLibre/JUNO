#!/bin/bash

PLATFORM=juno
MANIFEST=latest
TYPE=busybox

repo init -u https://git.linaro.org/landing-teams/working/arm/manifest -b 15.07 -m pinned-${MANIFEST}.xml
repo sync -j8
./build-scripts/build-all.sh ${PLATFORM}-${TYPE}
./build-scripts/build-all.sh ${PLATFORM}-${TYPE} package
