{ pkgs, ... }:
let
  utils = import ../utils.nix;
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkTraefikRoute "jellyfin" "http://127.0.0.1:8096";

  users.groups.media = {
    members = [ "jellyfin" ];
    gid = 3000;
  };

  # TODO wrap in container like nextcloud
  services.jellyfin = {
    enable = true;
    group = "media";
  };
}
