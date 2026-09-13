#!/bin/bash
set -euo pipefail
source /etc/borg/borg-backup.env

logger -t borg-external-test "external backup drive mounted"
rm -f "$EXTERNAL_MOUNT"/.mount-test-*
touch "$EXTERNAL_MOUNT/.mount-test-$(date +%s)"
