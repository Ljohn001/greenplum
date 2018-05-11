#!/bin/bash
grubby --update-kernel=ALL --args="elevator=deadline"
/sbin/blockdev --setra 16384 /dev/sdb1
grubby --update-kernel=ALL --args="transparent_hugepage=never"

echo "source /usr/local/greenplum-db/greenplum_path.sh >> /etc/bashrc"
echo "export MASTER_DATA_DIRECTORY=/data/gpmaster/gpseg-1 >> /etc/bashrc"
