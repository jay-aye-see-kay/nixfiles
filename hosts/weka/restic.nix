# Offsite backups: restic to Backblaze B2 (bucket weka-backups) through B2's
# S3 API, which restic's docs recommend over its native B2 backend.
#
# Every dataset under rpool/crypt/data is backed up, found from fileSystems,
# so a new app is included by default (as with sanoid). Each run backs up an
# atomic snapshot, rpool/crypt/data@restic, through .zfs/snapshot/restic, so
# files are crash-consistent without stopping services. Restored paths look
# like /var/lib/private/readeck/.zfs/snapshot/restic/...
#
# The repo password is also in 1Password ("weka restic"), and the B2 key too
# ("weka-backblaze"). Without them the backups can't be read if weka is lost.
# Manual use on weka: `sudo restic-weka snapshots` (wrapper with env set).
# @see: home-server/BACKUPS.md in dumpbox
{ config, lib, ... }:
let
  zfs = lib.getExe' config.boot.zfs.package "zfs";
  parent = "rpool/crypt/data";
  snap = "restic";
  dataMounts = lib.filter
    (fs: lib.hasPrefix "${parent}/" fs.device)
    (lib.attrValues config.fileSystems);
in
{
  sops.secrets.restic_b2_env = { };
  sops.secrets.restic_password = { };

  services.restic.backups.weka = {
    repository = "s3:https://s3.us-east-005.backblazeb2.com/weka-backups/weka";
    environmentFile = config.sops.secrets.restic_b2_env.path;
    passwordFile = config.sops.secrets.restic_password.path;
    initialize = true;

    paths = map (fs: "${fs.mountPoint}/.zfs/snapshot/${snap}") dataMounts;
    backupPrepareCommand = ''
      ${zfs} destroy -r ${parent}@${snap} 2>/dev/null || true
      ${zfs} snapshot -r ${parent}@${snap}
    '';
    backupCleanupCommand = ''
      ${zfs} destroy -r ${parent}@${snap}
    '';
    # Mealie's rotating logs are noise
    exclude = [ "mealie.log*" ];

    timerConfig = {
      OnCalendar = "02:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
    # Retention from BACKUPS.md: long enough to go back past silent corruption
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ];
    # Reads back a slice of the actual data each run, so the whole repo is
    # verified roughly every 50 days.
    checkOpts = [ "--read-data-subset=2%" ];
  };
}
