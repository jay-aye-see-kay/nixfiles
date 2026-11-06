{ config, pkgs-unstable, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 80 443 ];

  services.caddy.enable = true;

  # ---
  # === mealie ===
  # Moved to weka on 2026-11-07. Data left in /var/lib/private/mealie as a
  # fallback until it's deleted.
  # ---

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
  # === readeck ===
  # Moved to weka on 2026-11-06. Data left in /var/lib/private/readeck as a
  # fallback until it's deleted.
  # ---

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
