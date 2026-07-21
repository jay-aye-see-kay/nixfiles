{ config, pkgs, ... }:

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
    settings = {
      # ALLOW_SIGNUP = "false";
      BASE_URL = "https://mealie.h.jackrose.co.nz";
      OPENAI_API_KEY = "PLACEHOLDER_OPENAI_KEY";
    };
  };

  # ---
  # === linkding ===
  # https://github.com/sissbruecker/linkding
  # nixpkgs request: https://github.com/NixOS/nixpkgs/issues/341665
  # ---
  services.caddy.virtualHosts."linkding.h.jackrose.co.nz".extraConfig = ''
    reverse_proxy http://127.0.0.1:9090
  '';
  virtualisation.oci-containers.containers.linkding = {
    image = "sissbruecker/linkding";
    ports = [
      "127.0.0.1:9090:9090"
    ];
    volumes = [
      "/hs/linkding/:/etc/linkding/data"
      "/etc/localtime:/etc/localtime:ro"
    ];
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


  # ---
  # === windmill ===
  # https://www.windmill.dev/docs/advanced/self_host
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/web-apps/windmill.nix
  # ---
  # services.caddy.virtualHosts."windmill.h.jackrose.co.nz".extraConfig = ''
  #   reverse_proxy http://127.0.0.1:8001
  # '';
  # services.windmill = {
  #   enable = true;
  #   baseUrl = "https://windmill.h.jackrose.co.nz";
  # };
}
