# changelog

## unreleased

fixes found via vm-isolated fault-injection testing (see plan in session notes):

- `notify-test` now honors `--dry-run` (previously fired for real regardless)
- `borg-external-mount-test.sh` unmounts in managed mode, matching the man
  page's documented "clean unmount" verification flow
- `setup` verifies the mounted external drive's uuid before reusing an
  existing mount, so swapping drives without a clean unplug can't silently
  target the wrong disk
- flock-serialize local/external backup+check scripts per repo -
  `LOCK_WAIT` only protected the repo lock, not the local borg cache, so
  overlapping runs (manual `backup-now` racing the timer) could corrupt it
  permanently
- fix `systemctl --failed 'borg-*'` syntax bug in `status`/`test` -
  systemctl read the glob as a command verb and errored, silently
  swallowed by `2>/dev/null || true`, so the failed-units check never
  actually fired
- treat `borg create`'s exit 1 (warning, e.g. a file changed mid-backup) as
  non-fatal instead of letting `set -e` skip prune/compact and fire a
  false `OnFailure` notification for a routine, expected condition
- document that journald can drop a failing unit's own log lines when the
  disk is 100% full, so `journalctl` comes back empty right when it matters
- `mount-mode` applies the switch itself when the drive is plugged in, by
  replaying its udev insert event (`udevadm trigger --action=add`) instead
  of telling you to unplug/replug; asks first when switching to `managed`
  since that starts the armed target, and skips it during a running backup
