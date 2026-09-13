#!/bin/bash
set -euo pipefail
source /etc/borg/borg-backup.env

# same lock as borg-local-backup.sh - they share this repo's local cache,
# which isn't protected by borg's own --lock-wait (see that script)
exec {lock_fd}>/run/lock/borg-local.lock
flock -w "$LOCK_WAIT" "$lock_fd" || { echo "could not acquire local-repo lock within ${LOCK_WAIT}s - another run is still active" >&2; exit 1; }

export BORG_REPO="$LOCAL_REPO"
export BORG_PASSCOMMAND="cat '$PASSPHRASE_FILE'"

borg check --lock-wait "$LOCK_WAIT" --verbose
