{ config, pkgs, lib, ... }:
let
  privateKeyFile = config.sops.secrets.mullvadPrivateKey.path;
  utils = import ../utils.nix;
  containerIp = "192.168.100.12";
in
{
  services.traefik.dynamicConfigOptions = lib.mkMerge [
    (utils.mkProtectedTraefikRoute "radarr" "http://${containerIp}:7878")
    (utils.mkProtectedTraefikRoute "prowlarr" "http://${containerIp}:9696")
    (utils.mkProtectedTraefikRoute "sonarr" "http://${containerIp}:8989")
  ];

  systemd.tmpfiles.rules = [
    "d /data/sonarr/data - - - -"
    "d /data/radarr/data - - - -"
    "d /data/prowlarr/data - - - -"
  ];

  # Main container
  containers.servarr = {
    ephemeral = true;
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.2";
    localAddress = containerIp;

    bindMounts = {
      "${privateKeyFile}" = { hostPath = privateKeyFile; isReadOnly = true; };
      "/media" = { hostPath = "/media"; isReadOnly = false; };
      "/var/lib/sonarr/.config" = { hostPath = "/data/sonarr/data"; isReadOnly = false; };
      "/var/lib/radarr/.config" = { hostPath = "/data/radarr/data"; isReadOnly = false; };
      "/var/lib/private/prowlarr" = { hostPath = "/data/prowlarr/data"; isReadOnly = false; };
    };

    config = { pkgs, ... }:
      {
        # set permissions for host directories
        systemd.tmpfiles.rules = [
          "d /media/movies 777 radarr media -"
          "d /media/tv 777 sonarr media -"
          "d /media/transmission/download 777 transmission media -"
          "d /media/transmission/incomplete 777 transmission media -"
        ];

        networking.wg-quick.interfaces = {
          wg0 = {
            inherit privateKeyFile;
            address = [ "10.67.174.33/32" "fc00:bbbb:bbbb:bb01::4:ae20/128" ];
            dns = [ "193.138.218.74" ];
            peers = [
              {
                publicKey = "AYucpq+ZBJkPhIkJdpcDkUPG3xNrGUkQWCtmvCk1cFc=";
                allowedIPs = [ "0.0.0.0/0" "::0/0" ];
                endpoint = "89.45.90.236:51820";
              }
            ];
          };
        };

        networking.firewall = {
          allowedTCPPorts = [
            7878 # radarr
            8989 # sonarr
            9696 # prowlarr
          ];
          allowedUDPPorts = [ 51820 ]; # wireguard
        };

        users.groups.media = {
          members = [ "radarr" "radarr" "sonarr" "transmission" ];
          gid = 3000;
        };

        services.radarr = {
          enable = true;
          group = "media";
        };
        services.sonarr = {
          enable = true;
          group = "media";
        };
        services.prowlarr.enable = true;
        services.transmission = {
          enable = true;
          group = "media";
          settings.incomplete-dir = "/media/transmission/incomplete";
          settings.download-dir = "/media/transmission/download";
        };
      };
  };
}
