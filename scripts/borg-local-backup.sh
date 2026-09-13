#!/bin/bash
set -euo pipefail
source /etc/borg/borg-backup.env

# serialize against any other invocation touching this repo (a manual
# backup-now racing the timer, etc.) - --lock-wait only protects the repo
# itself; the local cache under ~/.cache/borg isn't covered by that lock and
# gets corrupted by truly concurrent borg processes
exec {lock_fd}>/run/lock/borg-local.lock
flock -w "$LOCK_WAIT" "$lock_fd" || { echo "could not acquire local-repo lock within ${LOCK_WAIT}s - another run is still active" >&2; exit 1; }

export BORG_REPO="$LOCAL_REPO"
export BORG_PASSCOMMAND="cat '$PASSPHRASE_FILE'"

# borg create exits 1 for warnings (e.g. a file changed while being read) on
# an otherwise-successful archive - only >=2 is a real error. Don't let
# set -e treat routine warnings on a live filesystem as a hard failure that
# skips prune/compact and fires the OnFailure notification.
set +e
borg create --lock-wait "$LOCK_WAIT" --stats --compression "$COMPRESSION" --exclude-caches \
    "${EXTRA_EXCLUDE_ARGS[@]}" \
    ::'{hostname}-{now:%Y-%m-%dT%H-%M-%S}' "${BACKUP_SOURCES[@]}"
create_rc=$?
set -e
[ "$create_rc" -ge 2 ] && exit "$create_rc"
[ "$create_rc" -eq 1 ] && echo "borg create finished with warnings (exit 1) - archive was created, continuing" >&2

borg prune --lock-wait "$LOCK_WAIT" --list "${RETENTION[@]}"
borg compact --lock-wait "$LOCK_WAIT"
