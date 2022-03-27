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
    ];
    allowedTCPPorts = [
      53 # dns
      80 # http
      443 # https
      465 # smtp
      25565 # minecraft
    ];
  };

  # connect nixos-containers to network
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "ens18";
  };

  imports = [
    ./mealie.nix
    ./nextcloud.nix
    # ./authelia.nix
    # ./homer.nix
    # ./jellyfin.nix
    # ./netdata.nix
    # ./photoprism.nix
    # ./servarr.nix
  ];
}
