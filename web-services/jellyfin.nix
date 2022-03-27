{ pkgs, ... }:
let
  dataDir = "/web-service-data/jellyfin";
  hostName = "jellyfin.h.jackrose.co.nz";
  localPort = "8096";
in
{
  services.nginx.virtualHosts."${hostName}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${localPort}";
      proxyWebsockets = true;
      extraConfig = "proxy_pass_header Authorization;";
    };
  };

  users.groups.media = {
    members = [ "jellyfin" ];
    gid = 3000;
  };

  services.jellyfin = {
    enable = true;
    group = "media";
  };
}
