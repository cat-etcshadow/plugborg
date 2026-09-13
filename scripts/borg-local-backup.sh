#!/bin/bash
set -euo pipefail
source /etc/borg/borg-backup.env

export BORG_REPO="$LOCAL_REPO"
export BORG_PASSCOMMAND="cat '$PASSPHRASE_FILE'"

borg create --lock-wait "$LOCK_WAIT" --stats --compression "$COMPRESSION" --exclude-caches \
    "${EXTRA_EXCLUDE_ARGS[@]}" \
    ::'{hostname}-{now:%Y-%m-%dT%H-%M-%S}' "${BACKUP_SOURCES[@]}"

borg prune --lock-wait "$LOCK_WAIT" --list "${RETENTION[@]}"
borg compact --lock-wait "$LOCK_WAIT"
