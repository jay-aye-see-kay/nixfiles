# Local ZFS snapshots of app data. Everything under rpool/crypt/data gets the
# same policy (BACKUPS.md), so a new app dataset is snapshotted by default.
# Copying them off the NVMe (syncoid to tank1) comes once tank1 moves across.
# See "ZFS datasets" in home-server/README.md in dumpbox.
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
    datasets."rpool/crypt/data" = {
      useTemplate = [ "data" ];
      recursive = true;
      # crypt/data itself holds nothing, only its children
      processChildrenOnly = true;
    };
  };
}
