# tank1: the 2× 4 TB WD Red Plus mirror. Media, /srv/hs (old experiments,
# still to be sorted), and syncoid's copy of rpool's app data.
#
# One encryption root (tank1 itself, keyformat passphrase). The key is in
# sops (and 1Password), and the pool's keylocation points at the decrypted
# copy (file:///run/secrets/tank1_key), so it imports and unlocks at boot
# with no prompt. sops decrypts during activation, before zfs-import-tank1.
#
# Mounts live here, as with rpool: the datasets that are mounted have
# mountpoint=legacy, and everything else on the pool is mountpoint=none, so
# ZFS never mounts anything by itself. Not in base/disko.nix, because disko would
# create (wipe) the pool on a reinstall. Services that need the media use
# RequiresMountsFor, so they stay down if tank1 is missing instead of writing
# into an empty directory on rpool.
let
  # nofail: if tank1 doesn't import, boot carries on (network, SSH, HA)
  # instead of stopping in emergency mode, which needs the keyboard.
  tank1Mount = dataset: {
    device = "tank1/${dataset}";
    fsType = "zfs";
    options = [ "nofail" ];
  };
in
{
  sops.secrets.tank1_key = { };

  boot.zfs.extraPools = [ "tank1" ];

  fileSystems."/srv/media" = tank1Mount "media";
  fileSystems."/srv/hs" = tank1Mount "hs";
}
