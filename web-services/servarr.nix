{ config, pkgs, lib, ... }:
let
  privateKeyFile = config.sops.secrets.mullvadPrivateKey.path;
  containerIp = "192.168.100.12";
  sonarrDataDir = "/web-service-data/sonarr";
  radarrDataDir = "/web-service-data/radarr";
  prowlarrDataDir = "/web-service-data/prowlarr";
  mediaDir = "/media";
  ports = {
    sonarr = 7878;
    radarr = 8989;
    prowlarr = 9696;
  };
  mkLocalProxy = port: {
    # quick function to expose these only on the local network, until I get proper auth setup
    listen = [{ addr = "192.168.1.72"; port = port; }];
    locations."/".proxyPass = "http://${containerIp}:${builtins.toString port}";
  };
in
{
  services.nginx.virtualHosts = {
    sonarr = mkLocalProxy ports.sonarr;
    radarr = mkLocalProxy ports.radarr;
    prowlarr = mkLocalProxy ports.prowlarr;
  };

  systemd.tmpfiles.rules = [
    "d ${sonarrDataDir} - - - -"
    "d ${radarrDataDir} - - - -"
    "d ${prowlarrDataDir} - - - -"
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
      "/media" = { hostPath = mediaDir; isReadOnly = false; };
      "/var/lib/sonarr/.config" = { hostPath = sonarrDataDir; isReadOnly = false; };
      "/var/lib/radarr/.config" = { hostPath = radarrDataDir; isReadOnly = false; };
      "/var/lib/private/prowlarr" = { hostPath = prowlarrDataDir; isReadOnly = false; };
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
            address = [ "10.64.201.123/32" "fc00:bbbb:bbbb:bb01::1:c97a/128" ];
            dns = [ "193.138.218.74" ];
            peers = [
              {
                publicKey = "qzi6yOzbLmoJXYYLzijkA5GO9lFhcEwglxI5qi4NpCI=";
                allowedIPs = [ "0.0.0.0/0" "::0/0" ];
                endpoint = "198.54.129.66:51820";
              }
            ];
          };
        };

        networking.firewall = {
          allowedTCPPorts = [
            ports.radarr
            ports.sonarr
            ports.prowlarr
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
