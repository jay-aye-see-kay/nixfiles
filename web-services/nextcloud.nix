{ config, pkgs, ... }:
let
  dataDir = "/web-service-data/nextcloud";
  hostName = "nextcloud.h.jackrose.co.nz";
in
{
  systemd.tmpfiles.rules = [
    "d ${dataDir} - nextcloud nextcloud -"
  ];

  services.nextcloud = {
    enable = true;
    https = true;
    home = dataDir;
    hostName = hostName;
    package = pkgs.nextcloud23;
    maxUploadSize = "2048M";
    autoUpdateApps = {
      enable = true;
      startAt = "05:00:00";
    };
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloudAdminPassword";
      defaultPhoneRegion = "AU";
    };
  };

  services.nginx.virtualHosts."${hostName}" = {
    forceSSL = true;
    enableACME = true;
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
}
