# borg-backup

two [borg](https://borgbackup.readthedocs.io/) repos, repokey-encrypted, run by root systemd units:

- **local** — on-disk repo, backed up on a timer (6h default)
- **external** — USB repo, backed up via udev rule on plug-in

full reference (commands, config vars, mount modes, notifications,
troubleshooting): `man borg-backup` (installed by setup), or
`man/borg-backup.8` in this tree before that.

## setup

```bash
sudo ./bin/borg-backup setup --dry-run   # preview
sudo ./bin/borg-backup setup             # do it
```

Asks what to back up, where the repos live, whether to add an external
drive (lists block devices, makes you retype the path before wiping it),
notifications, and a passphrase. Writes `/etc/borg/borg-backup.env`,
installs the CLI/scripts/units/man page, optionally partitions/inits/
enables timers — confirms before anything destructive. Re-run any time
to change settings; picks up prior answers.

`--dry-run` works on every `borg-backup` command, not just `setup`.

## verify it works

```bash
sudo borg-backup test        # add --full to also run borg check
```

Checks the passphrase, both repos, timers, failed units, notifications,
and external drive/arm state in one go — see `man borg-backup` for what
each check means and how to fix it.

Worth doing by hand once too: plug/unplug the external drive a few times
(no duplicate or overlapping runs), and deliberately break something
(rename `/etc/borg/passphrase`, run a backup, confirm it fails loudly,
restore it) before trusting this with real data.

## layout

```
bin/borg-backup                   the CLI
man/borg-backup.8                 the man page, installed by setup
config/borg-backup.env.example    template, for manual setup
scripts/*.sh                      backup/check/notify scripts -> /usr/local/sbin
systemd-files/*.service,*.timer   -> /etc/systemd/system as-is
systemd-files/*.service.tmpl      external-drive units, @MOUNT_UNIT@ substituted
systemd-files/borg-notify-failure@.service   OnFailure= target for every backup/check unit
udev/90-borg-external.rules.tmpl  -> /etc/udev/rules.d, UUID + wants substituted
```

everything host-specific lives in `/etc/borg/borg-backup.env`. setup also
mirrors this whole tree to `/usr/local/lib/borg-backup` and installs
`/usr/local/sbin/borg-backup` as a symlink into it, so `mount-mode`,
`arm-external`, and re-running `setup` keep working from the installed CLI
without the git checkout.

## manual setup

copy `config/borg-backup.env.example` to `/etc/borg/borg-backup.env`, edit it.
copy `bin/`, `scripts/`, `systemd-files/`, `udev/`, and `man/` to
`/usr/local/lib/borg-backup` (mode 700 for `bin/borg-backup` and
`scripts/*.sh`, 644 for the rest) — `mount-mode`/`arm-external` and setup
re-runs read from there afterward. symlink `/usr/local/lib/borg-backup/bin/borg-backup`
to `/usr/local/sbin/borg-backup`, and install `scripts/*.sh` mode 700
root:root to `/usr/local/sbin` too, plain `systemd-files/*.service,*.timer`
to `/etc/systemd/system`. for the external drive, render the `.service.tmpl`
files (`@MOUNT_UNIT@` = `systemd-escape --path --suffix=mount <mountpoint>`)
and the udev rule (`@EXTERNAL_FS_UUID@` from `blkid`, `@SYSTEMD_WANTS@` =
target service, plus the mount unit too if normal mode) into place without
the `.tmpl` suffix. `/etc/borg/passphrase` mode 600 root:root. `borg init`
both repos, enable the timers. optionally install `man/borg-backup.8` to
`/usr/local/share/man/man8/` and run `mandb`.

## design notes

- no `BORG_PASSPHRASE_FILE` in borg — use `BORG_PASSCOMMAND="cat <file>"`
- `borg compact` after `prune` (1.2+) — prune alone doesn't reclaim space
- borg logic lives in scripts, not unit files — sidesteps systemd's `%`
  escaping on the archive-name placeholder and multi-word `Environment=` bugs
- keep the local repo outside the backup sources (self-exclude otherwise;
  `EXTRA_EXCLUDE_ARGS` in the env file if you can't avoid it)
- external drive matched by filesystem UUID, not device path — device
  node naming isn't stable across reboots; UUID only needs to be right
  once, at partitioning time
- unclean unmount (yank, power loss) on ext4 shows write I/O errors even
  when idle, from routine journal commits — `passno 2` in the fstab entry
  means `systemd-fsck` replays the journal on next mount, so this is the
  expected recovery path, not data loss
- notification delivery is fire-and-forget and never blocks or fails a
  backup — see `man borg-backup` TROUBLESHOOTING §3
- the external repo self-inits on first backup after a fresh/replaced
  drive mounts (UUID match + successful mount are the authorization
  check) — see `man borg-backup` TROUBLESHOOTING §2. The local repo does
  not; `borg init` it or re-run `setup`

## requirements

borg (tested on 1.4.x), systemd, udev.
