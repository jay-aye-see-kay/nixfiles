{ config, pkgs, ... }:
let
  utils = import ../utils.nix;
  containerIp = "192.168.100.11";
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkTraefikRoute "nextcloud" "http://${containerIp}:80";

  systemd.tmpfiles.rules = [
    "d /data/nextcloud/data - - - -"
    "d /data/nextcloud/db - - - -"
  ];

  # Main container
  containers.nextcloud = {
    ephemeral = true;
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.2";
    localAddress = containerIp;

    bindMounts = {
      "/var/lib/nextcloud" = { hostPath = "/data/nextcloud/data"; isReadOnly = false; };
      "/var/lib/postgresql" = { hostPath = "/data/nextcloud/db"; isReadOnly = false; };
      "/media" = { hostPath = "/media"; isReadOnly = false; };
      "/photos" = { hostPath = "/photos/main"; isReadOnly = false; };
    };

    config = { pkgs, ... }:
      {
        users.users.nextcloud.uid = 3001;

        systemd.tmpfiles.rules = [
          "d /var/lib/postgres 700 postgres postgres -"
          "d /var/lib/nextcloud 770 nextcloud nextcloud -"
          "f /run/secrets/initialAdminPassword 400 nextcloud nextcloud - change-me-7259"
        ];

        networking.firewall.allowedTCPPorts = [ 80 ];
        services.nginx.enable = true;

        services.nextcloud = {
          enable = true;
          hostName = "localhost";
          package = pkgs.nextcloud23;
          config = {
            dbtype = "pgsql";
            dbuser = "nextcloud";
            dbhost = "/run/postgresql";
            dbname = "nextcloud";
            adminuser = "root";
            adminpassFile = "/run/secrets/initialAdminPassword";
            extraTrustedDomains = [ "nextcloud.h.jackrose.co.nz" ];
          };
        };

        services.postgresql = {
          enable = true;
          ensureDatabases = [ "nextcloud" ];
          ensureUsers = [
            {
              name = "nextcloud";
              ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
            }
          ];
        };

        # ensure that postgres is running *before* running the setup
        systemd.services."nextcloud-setup" = {
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
        };
      };
  };

  services.borgbackup.jobs.nextcloudBackup = {
    paths = "/data/nextcloud";
    repo = "/backups/nextcloud";
    doInit = true;
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.sops.secrets.borgPassword.path}";
    };
    compression = "auto,lzma";
    /* startAt = "minutely"; # TEMP: while setting up */
    startAt = "hourly";
    prune.keep = {
      within = "1d"; # Keep all archives from the last day
      daily = 7; # keep 1 per day for a week
      weekly = 4;
      monthly = -1; # Keep at least one archive for each month
    };
    # TODO remote backups
    preHook = ''
      ${pkgs.nixos-container}/bin/nixos-container run nextcloud -- nextcloud-occ maintenance:mode --on
      ${pkgs.nixos-container}/bin/nixos-container run nextcloud -- sudo -u nextcloud pg_dump -f /var/lib/nextcloud/db-backup.sql
    '';
    postHook = ''
      ${pkgs.nixos-container}/bin/nixos-container run nextcloud -- nextcloud-occ maintenance:mode --off
    '';
  };
}
