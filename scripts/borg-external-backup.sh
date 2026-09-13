#!/bin/bash
set -euo pipefail
source /etc/borg/borg-backup.env

# on any exit (success or failure) in managed mode, unmount - managed mode's
# whole point is a short mount window, so a mid-run failure shouldn't leave
# the drive mounted until someone notices
[ "${MOUNT_MODE:-managed}" = managed ] && trap 'umount "$EXTERNAL_MOUNT" 2>/dev/null || true' EXIT

export BORG_REPO="$EXTERNAL_REPO"
export BORG_PASSCOMMAND="cat '$PASSPHRASE_FILE'"

# first backup to a fresh/replaced drive - UUID match + successful mount already
# confirm it's the right drive, so init it here rather than failing forever
if [ ! -f "$EXTERNAL_REPO/config" ]; then
    echo "repo not found at $EXTERNAL_REPO, initializing"
    borg init --lock-wait "$LOCK_WAIT" --encryption=repokey --make-parent-dirs "$EXTERNAL_REPO"
    /usr/local/sbin/borg-notify.sh "external backup" "no repo found at $EXTERNAL_REPO, initialized a new one"
fi

borg create --lock-wait "$LOCK_WAIT" --stats --compression "$COMPRESSION" --exclude-caches \
    ::'{hostname}-{now:%Y-%m-%dT%H-%M-%S}' "${BACKUP_SOURCES[@]}"

borg prune --lock-wait "$LOCK_WAIT" --list "${RETENTION[@]}"
borg compact --lock-wait "$LOCK_WAIT"

# throttle check to once every CHECK_INTERVAL_DAYS - kept outside the repo
# dir itself (which should only ever hold borg-managed files)
stamp="$EXTERNAL_MOUNT/.borg-last-check"
if [ ! -e "$stamp" ] || [ -n "$(find "$stamp" -mtime "+$CHECK_INTERVAL_DAYS")" ]; then
    borg check --lock-wait "$LOCK_WAIT" --verbose
    touch "$stamp"
fi

# managed mode mounts only for the backup (trap above unmounts on exit);
# normal mode leaves it mounted until unplugged
if [ "${MOUNT_MODE:-managed}" = managed ]; then
    /usr/local/sbin/borg-notify.sh "external backup done" "archive created, drive unmounted"
else
    /usr/local/sbin/borg-notify.sh "external backup done" "archive created, drive still mounted"
fi
