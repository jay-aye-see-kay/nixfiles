# Disk layout for weka's 1 TB NVMe (Samsung 970 EVO), applied by disko at install.
# ESP + one ZFS pool. Everything under rpool/crypt is natively encrypted with a
# passphrase, unlocked over SSH in the initrd (port 2222).
# @see: https://github.com/nix-community/disko/blob/master/example/zfs-encrypted-root.nix
{
  disko.devices = {
    disk.main = {
      type = "disk";
      # Only NVMe in the box. Check with `lsblk` before installing.
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        mountpoint = "none";
        compression = "zstd";
        acltype = "posixacl";
        xattr = "sa";
        atime = "off";
        "com.sun:auto-snapshot" = "false";
      };

      datasets = {
        # During install the passphrase is read from /tmp/secret.key (passed in
        # by nixos-anywhere), then switched to prompt for every boot after.
        crypt = {
          type = "zfs_fs";
          options = {
            mountpoint = "none";
            encryption = "aes-256-gcm";
            keyformat = "passphrase";
            keylocation = "file:///tmp/secret.key";
          };
          postCreateHook = ''
            zfs set keylocation="prompt" "rpool/$name";
          '';
        };
        "crypt/root" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };
        "crypt/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "legacy";
        };
        "crypt/home" = {
          type = "zfs_fs";
          mountpoint = "/home";
          options.mountpoint = "legacy";
        };
        # Parent for per-app datasets (sanoid targets these, not root or nix).
        "crypt/data" = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        # Space held back so a full pool can still be cleaned up.
        reserved = {
          type = "zfs_fs";
          options = {
            mountpoint = "none";
            refreservation = "20G";
          };
        };
      };
    };
  };
}
