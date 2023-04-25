{ config, pkgs, ... }:
let
  dataDir = "/var/lib/authelia";

  autheliaCfg = builtins.toFile "authelia-config.yaml" (builtins.toJSON {
    storage = {
      local.path = "${dataDir}/db.sqlite3";
    };
    authentication_backend.file = {
      # generate password hash with: authelia crypto hash generate argon2 --password '<password>'
      path = "${dataDir}/users.yaml";
      watch = true;
    };
    session.domain = "jackrose.co.nz";
    notifier.filesystem.filename = "${dataDir}/notification.txt";
    access_control = {
      default_policy = "deny";
      rules = [
        { domain = "*.p.jackrose.co.nz"; policy = "one_factor"; }
      ];
    };
    totp.issuer = "p.jackrose.co.nz";
  });
in
{
  users.users.authelia = {
    isSystemUser = true;
    group = "authelia";
  };
  users.groups.authelia = { };

  systemd.services.authelia = {
    description = "Authelia authentication and authorization server";
    wantedBy = [ "multi-user.target" ];
    environment = {
      AUTHELIA_JWT_SECRET_FILE = "/var/authelia/jwt_secret";
      AUTHELIA_SESSION_SECRET_FILE = "/var/authelia/session_secret";
      AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "/var/authelia/storage_key";
    };
    serviceConfig = {
      User = "authelia";
      Group = "authelia";
      ExecStart = "${pkgs.unstable.authelia}/bin/authelia --config ${autheliaCfg}";
      StateDirectory = [ "authelia" ];
      LogsDirectory = [ "authelia" ];
      TimeoutStopSec = "5s"; # HACK: setting this to a low value because it doesn't seem to stop?
    };
  };
}
