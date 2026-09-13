#!/bin/bash
set -euo pipefail
source /etc/borg/borg-backup.env

# managed mode's whole point is a short mount window - match the real backup
# script's behavior so the documented verification flow ("plug/unplug and
# confirm a clean unmount") is actually true while armed at the test target
[ "${MOUNT_MODE:-managed}" = managed ] && trap 'umount "$EXTERNAL_MOUNT" 2>/dev/null || true' EXIT

logger -t borg-external-test "external backup drive mounted"
rm -f "$EXTERNAL_MOUNT"/.mount-test-*
touch "$EXTERNAL_MOUNT/.mount-test-$(date +%s)"
