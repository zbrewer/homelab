#!/bin/bash

apt update
apt install -y sudo smartmontools nvme-cli rrdtool

echo "telegraf ALL=NOPASSWD:/usr/sbin/smartctl" >> /etc/sudoers
echo "telegraf ALL = NOPASSWD: /mnt/zfs_libs/zpool_influxdb" >> /etc/sudoers
echo "Defaults:telegraf !requiretty, !syslog" >> /etc/sudoers

export PATH="/mnt/zfs_libs:$PATH"

set -e
if [ "${1:0:1}" = '-' ]; then
set -- telegraf "$@"
fi

if [ $EUID -ne 0 ]; then
exec "$@"
else
setcap cap_net_raw,cap_net_bind_service+ep /usr/bin/telegraf || echo "Failed to set additional capabilities on /usr/bin/telegraf"
exec setpriv --reuid telegraf --init-groups "$@"
fi

ldconfig

echo "Custom Entrypoint Startup Complete"
