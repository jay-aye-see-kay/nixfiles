{ config, pkgs-unstable, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 80 443 ];

  services.caddy.enable = true;

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
  # === readeck ===
  # https://readeck.org/en/docs/configuration
  # ---
  services.caddy.virtualHosts."readeck.h.jackrose.co.nz".extraConfig = ''
    reverse_proxy http://127.0.0.1:9091
  '';
  services.readeck = {
    enable = true;
    # Provide READECK_SECRET_KEY out-of-store so Readeck doesn't try to
    # generate one and write it back into its read-only nix-store config.
    # Create on the host once with:
    #   umask 077
    #   printf 'READECK_SECRET_KEY=%s\n' "$(openssl rand -hex 32)" > /var/lib/readeck/readeck.env
    environmentFile = "/var/lib/readeck/readeck.env";
    settings = {
      server.host = "127.0.0.1";
      server.port = 9091;
      server.base_url = "https://readeck.h.jackrose.co.nz";
      server.trusted_proxies = [ "127.0.0.1" ];
    };
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
