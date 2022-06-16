{ config, pkgs, lib, ... }:
let
  utils = import ../utils.nix;
in
{
  services.fail2ban.enable = true;

  security.acme = {
    acceptTerms = true;
    email = "user+acme@jackrose.co.nz";
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };

  networking.firewall = {
    allowedUDPPorts = [
      53 # dns
      465 # smtp
      25565 # minecraft
      51820 # wireguard
      8080 # kodi
    ];
    allowedTCPPorts = [
      53 # dns
      80 # http
      443 # https
      465 # smtp
      25565 # minecraft

      8080 # kodi
      7878 # radarr
      8989 # sonarr
      9696 # prowlarr
    ];
  };

  # connect nixos-containers to network
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp7s0";
  };

  imports = [
    ./jellyfin.nix
    ./mealie.nix
    ./nextcloud.nix
    ./servarr.nix
    ./minecraft.nix
    ./puffer-panel.nix
    # ./authelia.nix
    # ./homer.nix
    # ./netdata.nix
    # ./photoprism.nix
  ];
}
