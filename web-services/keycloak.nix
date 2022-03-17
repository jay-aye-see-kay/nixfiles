{ pkgs, config, ... }:
let
  utils = import ../utils.nix;
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkTraefikRoute "keycloak" "http://127.0.0.1:9990";

  services.keycloak = {
    enable = true;
    initialAdminPassword = "changeme";
    frontendUrl = "";
    database = {
      type = "postgresql";
      passwordFile = config.sops.secrets.keycloakDbPassword.path;
    };
  };
}
