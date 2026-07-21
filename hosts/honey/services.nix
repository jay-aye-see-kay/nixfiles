{ config, pkgs, pkgs-unstable, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 80 443 ];

  services.caddy.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_29;
  virtualisation.oci-containers.backend = "docker";

  # ---
  # === mealie ===
  # https://github.com/mealie-recipes/mealie
  # ---
  services.caddy.virtualHosts."mealie.h.jackrose.co.nz".extraConfig = ''
    reverse_proxy http://127.0.0.1:9000
  '';
  services.mealie = {
    enable = true;
    package = pkgs-unstable.mealie;
    settings = {
      ALLOW_SIGNUP = "false";
      BASE_URL = "https://mealie.h.jackrose.co.nz";
    };
  };

  # ---
  # === linkding ===
  # https://github.com/sissbruecker/linkding
  # ---
  services.caddy.virtualHosts."linkding.h.jackrose.co.nz".extraConfig = ''
    reverse_proxy http://127.0.0.1:9090
  '';
  services.linkding = {
    enable = true;
    dataDir = "/hs/linkding";
    address = "127.0.0.1";
    port = 9090;
  };

  # ---
  # === crafty ===
  # https://docs.craftycontrol.com/
  # ---
  # services.caddy.virtualHosts."crafty.h.jackrose.co.nz".extraConfig = ''
  #   reverse_proxy https://192.168.30.100:8443 {
  #     transport http {
  #       tls
  #       tls_insecure_skip_verify
  #     }
  #   }
  # '';


  # ---
  # === jellyfin ===
  # https://wiki.nixos.org/wiki/Jellyfin
  # ---
  services.caddy.virtualHosts."jellyfin.h.jackrose.co.nz".extraConfig = ''
    reverse_proxy http://127.0.0.1:8096
  '';
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };


  # ---
  # === plex ===
  # https://wiki.nixos.org/wiki/Plex
  # ---
  services.plex = {
    enable = true;
    openFirewall = true;
  };
}
