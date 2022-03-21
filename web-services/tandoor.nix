{ pkgs, lib, ... }:
let
  utils = import ../utils.nix;
  port = "1503";
  configFile = builtins.toFile "tandoor-secrets-env" ''
  '';
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkTraefikRoute "tandoor" "http://127.0.0.1:${port}";

  services.postgresql = {
    # is this the way get a db?
    enable = true;
    ensureDatabases = [ "tandoor" ];
    ensureUsers = [
      {
        name = "tandoor";
        ensurePermissions."DATABASE tandoor" = "ALL PRIVILEGES";
      }
    ];
  };

  virtualisation.oci-containers.containers.tandoor = {
    autoStart = true;
    image = "vabene1111/recipes";
    extraOptions = [ "--network=host" ];
    environment = {
      SECRET_KEY = "foo"; # FIXME
      DB_ENGINE = "django.db.backends.postgresql";
      POSTGRES_HOST = "localhost";
      POSTGRES_PORT = "5432";
      POSTGRES_USER = "tandoor";
      POSTGRES_PASSWORD = "foo"; # FIXME
      POSTGRES_DB = "tandoor";
      TANDOOR_PORT = "${port}";
    };
    /* volumes = [ # TODO need volumes */
    /*   "${configFile}:/www/assets/config.yml" */
    /* ]; */
  };
}
