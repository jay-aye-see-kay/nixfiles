# Local ZFS snapshots of app data. Everything under rpool/crypt/data gets the
# same policy (BACKUPS.md), so a new app dataset is snapshotted by default.
# syncoid copies those snapshots off the NVMe to tank1/backup/weka daily, so
# losing the NVMe doesn't mean a B2 download. Media gets daily snapshots only:
# it isn't backed up anywhere else, on purpose (replaceable, terabytes).
# See "ZFS datasets" in home-server/README.md and "ZFS snapshots" in
# home-server/BACKUPS.md in dumpbox.
# @see: https://github.com/jimsalterjrs/sanoid
{
  services.sanoid = {
    enable = true;
    templates.data = {
      hourly = 24;
      daily = 30;
      monthly = 6;
      autosnap = true;
      autoprune = true;
    };
    # Deleted media only frees space once these expire
    templates.media = {
      hourly = 0;
      daily = 14;
      monthly = 0;
      autosnap = true;
      autoprune = true;
    };
    # syncoid's copies: no new snapshots, only pruning, and kept longer.
    # Hourlies kept as on the source so each run is a small incremental.
    templates.backup = {
      hourly = 24;
      daily = 30;
      monthly = 12;
      autosnap = false;
      autoprune = true;
    };
    datasets."rpool/crypt/data" = {
      useTemplate = [ "data" ];
      recursive = true;
      # crypt/data itself holds nothing, only its children
      processChildrenOnly = true;
    };
    datasets."tank1/media".useTemplate = [ "media" ];
    datasets."tank1/backup/weka" = {
      useTemplate = [ "backup" ];
      recursive = true;
      processChildrenOnly = true;
    };
  };

  # Not a raw send, so the copies take on tank1's encryption and its key
  # unlocks them. They inherit mountpoint=none from tank1/backup, so they're
  # never mounted. --no-sync-snap sends sanoid's own snapshots instead of
  # adding syncoid ones. Runs after restic (02:00 + up to 1 h).
  services.syncoid = {
    enable = true;
    interval = "*-*-* 03:30:00";
    commands."rpool/crypt/data" = {
      target = "tank1/backup/weka";
      recursive = true;
      extraArgs = [ "--no-sync-snap" "--skip-parent" ];
    };
  };
}
