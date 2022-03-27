{ pkgs, ... }:
let
  hostName = "nextcloud.h.jackrose.co.nz";
  dataDir = "/web-service-data/nextcloud";
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
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloudAdminPassword";
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
