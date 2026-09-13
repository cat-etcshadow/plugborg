#!/bin/bash
set -euo pipefail
source /etc/borg/borg-backup.env

export BORG_REPO="$LOCAL_REPO"
export BORG_PASSCOMMAND="cat '$PASSPHRASE_FILE'"

borg check --lock-wait "$LOCK_WAIT" --verbose
