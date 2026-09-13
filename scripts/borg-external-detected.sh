#!/bin/bash
# the same physical plug-in fires several udev add events for the partition
# while the drive settles, spread across the whole mount window - debounce
set -euo pipefail
source /etc/borg/borg-backup.env

stamp=/run/borg-external-detected.stamp
debounce=20

now=$(date +%s)
last=$(cat "$stamp" 2>/dev/null || echo 0)
[ $((now - last)) -ge "$debounce" ] || exit 0
echo "$now" > "$stamp"

if [ "${MOUNT_MODE:-managed}" = normal ]; then
    /usr/local/sbin/borg-notify.sh "external backup drive" "detected, mounting"
else
    /usr/local/sbin/borg-notify.sh "external backup drive" "detected, mounting/backup starting"
fi
