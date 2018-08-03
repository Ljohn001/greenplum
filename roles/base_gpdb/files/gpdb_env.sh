#!/bin/bash
sysctl -p
/sbin/blockdev --setra 65535 /dev/sdb1
grubby --update-kernel=ALL --args="transparent_hugepage=never"
