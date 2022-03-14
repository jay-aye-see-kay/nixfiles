{ pkgs, ... }:
let
  utils = import ../utils.nix;
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkTraefikRoute "homer" "http://127.0.0.1:10001";

  virtualisation.oci-containers.containers.homer = {
    autoStart = true;
    image = "b4bz/homer:latest";
    ports = [
      "10001:8080"
    ];
    volumes = [
      "/data/homer/data:/www/assets"
    ];
  };
}
