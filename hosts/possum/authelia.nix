{ config, pkgs, ... }:
let
  dataDir = "/var/lib/authelia";

  autheliaCfg = builtins.toFile "authelia-config.yaml" (builtins.toJSON {
    storage = {
      local.path = "${dataDir}/db.sqlite3";
    };
    authentication_backend.file = {
      path = "${dataDir}/users.yaml";
      watch = true;
    };
    session.domain = "jackrose.co.nz";
    notifier.filesystem.filename = "${dataDir}/notification.txt";
    access_control = {
      default_policy = "deny";
      rules = [
        { domain = "*.p.jackrose.co.nz"; policy = "two_factor"; }
      ];
    };
    totp.issuer = "p.jackrose.co.nz";
  });
in
{
  sops.secrets = let autheliaUser = config.users.users.authelia.name; in
    {
      autheliaJwtSecret.owner = autheliaUser;
      autheliaSessionSecret.owner = autheliaUser;
      autheliaStorageEncryptionKey.owner = autheliaUser;
    };

  users.users.authelia = {
    isSystemUser = true;
    group = "authelia";
  };
  users.groups.authelia = { };

  systemd.services.authelia = {
    description = "Authelia authentication and authorization server";
    wantedBy = [ "multi-user.target" ];
    environment = with config.sops.secrets; {
      AUTHELIA_JWT_SECRET_FILE = "${autheliaJwtSecret.path}";
      AUTHELIA_SESSION_SECRET_FILE = "${autheliaSessionSecret.path}";
      AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "${autheliaStorageEncryptionKey.path}";
    };
    serviceConfig = {
      User = "authelia";
      Group = "authelia";
      ExecStart = "${pkgs.authelia}/bin/authelia --config ${autheliaCfg}";
      StateDirectory = [ "authelia" ];
      LogsDirectory = [ "authelia" ];
      TimeoutStopSec = "5s"; # HACK: setting this to a low value because it doesn't seem to stop?
    };
  };
}
