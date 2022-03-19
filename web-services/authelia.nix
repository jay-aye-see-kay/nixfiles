{ pkgs, config, ... }:
let
  utils = import ../utils.nix;
  port = "1052";

  configFile = builtins.toFile "homer-config" (builtins.toJSON {
    default_redirection_url = "https://h.jackrose.co.nz";
    server = {
      host = "0.0.0.0";
      port = 9091;
    };
    authentication_backend.file.path = "/config/users_database.yml";
    storage.local.path = "/config/db.sqlite3";
    totp.issuer = "h.jackrose.co.nz";
    access_control.default_policy = "one_factor";
    session = {
      name = "authelia_session";
      expiration = 3600; # 1 hour
      inactivity = 300; # 5 minutes
      domain = "h.jackrose.co.nz"; # Should match whatever your root protected domain is
    };
    regulation = {
      max_retries = 3;
      find_time = 120;
      ban_time = 300;
    };
    notifier.smtp = {
      host = "smtp.migadu.com";
      port = 465;
      username = "services@jackrose.co.nz";
      sender = "services@jackrose.co.nz";
    };
  });
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkTraefikRoute "auth" "http://127.0.0.1:${port}";

  /* services.redis.enable = true; */

  virtualisation.oci-containers.containers.authelia = {
    autoStart = true;
    image = "authelia/authelia";
    cmd = [ "--config" configFile ];
    environment = {
      TZ = "Australia/Melbourne";
      AUTHELIA_JWT_SECRET_FILE = config.sops.secrets.autheliaJwtSecret.path;
      AUTHELIA_SESSION_SECRET_FILE = config.sops.secrets.autheliaSessionSecret.path;
      AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = config.sops.secrets.autheliaStorageEncryptionKey.path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets.serviceMailAccountPassword.path;
    };
    ports = [
      "${port}:9091"
    ];
    volumes = [
      "${configFile}:${configFile}"
      "/data/authelia/data:/config"
      "/run/secrets:/run/secrets"
    ];
  };
}
