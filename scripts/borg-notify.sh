#!/bin/bash
# borg-notify.sh <title> <message> - desktop notification to NOTIFY_USER; no-op if unset or nobody's logged in
set -euo pipefail
source /etc/borg/borg-backup.env

[ -n "${NOTIFY_USER:-}" ] || exit 0
command -v notify-send >/dev/null 2>&1 || exit 0

uid=$(id -u "$NOTIFY_USER" 2>/dev/null) || exit 0
bus="/run/user/$uid/bus"
[ -S "$bus" ] || exit 0

runuser -u "$NOTIFY_USER" -- env \
    XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
    notify-send "$@"
