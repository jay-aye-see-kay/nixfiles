{ pkgs, ... }:
let
  utils = import ../utils.nix;
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkProtectedTraefikRoute "netdata" "http://127.0.0.1:19999";

  services.netdata.enable = true;
}
