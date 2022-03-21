{ pkgs, lib, ... }:
let
  utils = import ../utils.nix;
  port = "1504";
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkTraefikRoute "mealie" "http://127.0.0.1:${port}";

  virtualisation.oci-containers.containers.mealie = {
    autoStart = true;
    image = "hkotel/mealie";
    environment = {
      TZ = "Australia/Melbourne";
      RECIPE_PUBLIC = "true";
      RECIPE_SHOW_NUTRITION = "true";
      RECIPE_SHOW_ASSETS = "true";
      RECIPE_LANDSCAPE_VIEW = "true";
      RECIPE_DISABLE_COMMENTS = "false";
      RECIPE_DISABLE_AMOUNT = "false";
    };
    ports = [
      "${port}:80"
    ];
    volumes = [
      "/data/mealie/data:/app/data"
    ];
  };
}
