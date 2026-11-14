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
        # Parent for per-app datasets. sanoid snapshots it recursively, so a new
        # app here is snapshotted by default. Data that shouldn't be snapshotted
        # (metrics, caches) goes under a separate crypt/nosnap parent instead.
        # See "Adding an app" and "Storage" in README.md.
        "crypt/data" = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        # Per-app datasets. disko only runs at install, so on the live system
        # create each one by hand before the first deploy that mounts it:
        #   sudo zfs create -o mountpoint=legacy rpool/crypt/data/<app>
        # DynamicUser services keep state in /var/lib/private/<app>, others in
        # /var/lib/<app>.
        "crypt/data/readeck" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/private/readeck";
          options.mountpoint = "legacy";
        };
        "crypt/data/mealie" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/private/mealie";
          options.mountpoint = "legacy";
        };
        "crypt/data/grafana" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/grafana";
          options.mountpoint = "legacy";
        };
        # Samba shares (files.nix)
        "crypt/data/files" = {
          type = "zfs_fs";
          mountpoint = "/srv/files";
          options.mountpoint = "legacy";
        };
        # Paperless: SQLite, search index and media together, so one snapshot
        # covers the database and the documents it points at.
        "crypt/data/paperless" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/paperless";
          options.mountpoint = "legacy";
        };
        # Home Assistant config and state (home-assistant.nix)
        "crypt/data/hass" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/hass";
          options.mountpoint = "legacy";
        };
        # Minecraft worlds (a Crafty 4 servers dir, its backups and DB).
        # Archive only, no server runs on them.
        "crypt/data/minecraft" = {
          type = "zfs_fs";
          mountpoint = "/srv/minecraft";
          options.mountpoint = "legacy";
        };
        # Jellyfin and Plex state: watch history, metadata, artwork. The
        # media itself is on tank1 (tank1.nix).
        "crypt/data/jellyfin" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/jellyfin";
          options.mountpoint = "legacy";
        };
        "crypt/data/plex" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/plex";
          options.mountpoint = "legacy";
        };
        # The *arrs (arr.nix). Prowlarr is DynamicUser, the others aren't.
        "crypt/data/prowlarr" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/private/prowlarr";
          options.mountpoint = "legacy";
        };
        "crypt/data/sonarr" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/sonarr";
          options.mountpoint = "legacy";
        };
        "crypt/data/radarr" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/radarr";
          options.mountpoint = "legacy";
        };
        "crypt/data/lidarr" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/lidarr";
          options.mountpoint = "legacy";
        };
        # Settings, categories and resume data. The downloads themselves are
        # on tank1 (/srv/media/downloads).
        "crypt/data/qbittorrent" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/qBittorrent";
          options.mountpoint = "legacy";
        };
        # Parent for data that isn't snapshotted or backed up: it churns, and
        # losing it is accepted (Prometheus history, Loki logs). Same
        # create-by-hand step as crypt/data/<app>, but under crypt/nosnap.
        "crypt/nosnap" = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "crypt/nosnap/prometheus" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/prometheus2";
          options.mountpoint = "legacy";
        };
        "crypt/nosnap/loki" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/loki";
          options.mountpoint = "legacy";
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
