#!/bin/bash

ifconfig eth0 | sed -n 's/.*inet *addr:\([0-9\.]*\).*/\1/p'
