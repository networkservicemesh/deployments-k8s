#!/bin/bash
# shellcheck disable=SC2002,SC2181

# Wait for "/dev/vfio/vfio" to appear
#####################################
# until find /dev/vfio/vfio; do
#   sleep 1
# done

# Wait for "c 10:196" to be added in devices cgroup
###################################################
# until grep "c 10:196" /sys/fs/cgroup/devices/devices.list; do
#   sleep 1
# done

# Run dpdk-pingpong (client)
/root/dpdk-pingpong/build/app/pingpong \
  --no-huge \
  -- \
  -n 500 \
  -c \
  -C 0a:11:22:33:44:55 \
  -S 0a:55:44:33:22:11
