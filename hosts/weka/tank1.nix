# tank1: the 2× 4 TB WD Red Plus mirror that came from pm1. Media, the old
# /srv/hs experiments, and syncoid's copy of rpool's app data.
#
# One encryption root (tank1 itself, keyformat passphrase). Its key is its
# own, not the one pm1's rpool/data used, although both sat at /.data.key on
# pm1. It's in sops (and 1Password), and the pool's keylocation points at the
# decrypted copy, so it imports and unlocks at boot with no prompt. sops
# decrypts during activation, before zfs-import-tank1. First import on weka
# needed -f (pm1's hostid), done by hand.
#
# Native mountpoints (/srv/media, /srv/hs), unlike rpool's legacy ones.
# tank1/data (innie's old disk) and tank1/images are canmount=off: kept, but
# not mounted.
# @see: home-server/MIGRATION.md step 6 in dumpbox
{
  sops.secrets.tank1_key = { };

  boot.zfs.extraPools = [ "tank1" ];
}
